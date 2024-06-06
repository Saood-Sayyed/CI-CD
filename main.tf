provider "aws" {
  region = "us-east-1"
}

# Step 1: Create a CodeCommit Repository
resource "aws_codecommit_repository" "code_repo" {
  repository_name = "CI-CD-Repository"
  description     = "Code repository for the application"
}

# Step 2: Create an S3 Bucket for Artifacts
resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = ""
 
}

# Step 3: Create a CodeBuild Project

# IAM Role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess"
}

# CodeBuild Project
resource "aws_codebuild_project" "codebuild_project" {
  name          = "ApplicationBuildProject"
  service_role  = aws_iam_role.codebuild_role.arn
  artifacts {
    type      = "S3"
    location  = aws_s3_bucket.codepipeline_artifacts.bucket
    packaging = "ZIP"
  }
  environment {
    compute_type         = "BUILD_GENERAL1_SMALL"
    image                = "aws/codebuild/standard:4.0"
    type                 = "LINUX_CONTAINER"
    environment_variable {
      name  = "ENV_VAR1"
      value = "value1"
    }
  }
  source {
    type      = "CODECOMMIT"
    location  = aws_codecommit_repository.code_repo.clone_url_http
  }
}

# Step 4: Create a CodeDeploy Application and Deployment Group

# IAM Role for CodeDeploy
resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codedeploy.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy_attachment" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# CodeDeploy Application and Deployment Group
resource "aws_codedeploy_app" "codedeploy_app" {
  name = "ApplicationDeployApp"
}

resource "aws_codedeploy_deployment_group" "codedeploy_deployment_group" {
  app_name              = aws_codedeploy_app.codedeploy_app.name
  deployment_group_name = "ApplicationDeploymentGroup"
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
  
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      value = "ApplicationEC2Instance"
      type  = "KEY_AND_VALUE"
    }
  }
}

# Step 5: Create a CodePipeline

# IAM Role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline-policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codepipeline:PutJobSuccessResult",
          "codepipeline:PutJobFailureResult",
          "codepipeline:PollForJobs",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:UploadArchive",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:CancelUploadArchive",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_codepipeline" "codepipeline" {
  name     = "ApplicationPipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_artifacts.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = aws_codecommit_repository.code_repo.repository_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_project.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.codedeploy_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.codedeploy_deployment_group.deployment_group_name
      }
    }
  }
}
