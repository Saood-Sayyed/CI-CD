
Step 3: Create a CodeBuild Project
    1. IAM Role for CodeBuild
        Create an IAM role "codebuild-role" with a policy allowing CodeBuild service to assume this role. 
        Attaches the 'AWSCodeBuildDeveloperAccess' policy to this role, granting necessary permissions for CodeBuild operations  

    2. CodeBuild project

        Defines a CodeBuild project "ApplicationBuildProject" with specified configurations:
            service_role: Specifies the IAM role that CodeBuild will use.
            artifacts: Configures build artifacts to be stored in the S3 bucket created earlier.
            environment: Defines the build environment, including compute type, image, and environment variables.
            source: Specifies the source repository for the build, which is the CodeCommit repository created earlier.


Step 4: Create a CodeDeploy Application and Deployment Group
    1. IAM Role for CodeDeploy
       Creates an IAM role for CodeDeploy with a trust policy allowing CodeDeploy service to assume this role. 
       Attaches the 'AWSCodeDeployRole' policy to this role, granting necessary permissions for CodeDeploy operations.

    2. CodeDeploy Application and Deployment Group
        Defines a CodeDeploy application named "ApplicationDeployApp" and a deployment group named "ApplicationDeploymentGroup" with specified configurations:
            service_role_arn: Specifies the IAM role that CodeDeploy will use.
            deployment_config_name: Sets the deployment configuration.
            auto_rollback_configuration: Enables automatic rollback on deployment failure.
            ec2_tag_set: Specifies EC2 instances by tags where the application will be deployed.

Step 5: Create a CodePipeline
    1. IAM Role for CodePipeline
        Creates an IAM role for CodePipeline with a trust policy allowing CodePipeline service to assume this role. 
        Attaches a policy with necessary permissions for CodePipeline operations, including interacting with various AWS services involved in the CI/CD process.
    
        Defines a CodePipeline named "ApplicationPipeline" with specified configurations:

            role_arn: Specifies the IAM role that CodePipeline will use.

            artifact_store: Configures the S3 bucket created earlier to store pipeline artifacts.

            stages: Defines pipeline stages, each containing actions to perform specific tasks such as source code retrieval, build, and deployment.

            Source Stage: Retrieves source code from the CodeCommit repository.

            Build Stage: Builds the application using CodeBuild.

            Deploy Stage: Deploys the application using CodeDeploy.
