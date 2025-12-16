CI/CD Pipeline with GitHub Actions and Docker

This repository demonstrates a foundational Continuous Integration and Continuous Deployment (CI/CD) pipeline using GitHub Actions to automate the building, testing, and publishing of a Docker image to a Container Registry.

The project ensures that every code change is validated and prepared for deployment automatically.
✨ Key Features
    • Automated Workflow: The pipeline is defined in a YAML file (.github/workflows/main.yml) and is triggered on every push to the main branch.
    • Secure Authentication: Utilizes the built-in and secure ${{ secrets.GITHUB_TOKEN }} for authentication with the GitHub Container Registry (GHCR).
    • Version Tagging: Automatically tags the Docker image with both the commit SHA (for traceability) and the latest tag (for easy deployment).
    • Industry Standard Actions: Leverages official GitHub Actions like actions/checkout and docker/build-push-action for reliable execution.

⚙️ Technology Stack

Component
Tool/Language
Purpose
Orchestration
GitHub Actions
Defines the CI/CD pipeline and manages job execution.
Containerization
Docker
Packages the application and its environment into a portable image.
Registry
GitHub Container Registry (GHCR)
Securely hosts and versions the final Docker images.

Source Code
The code being tested and containerized.

🏗️ Architecture and Workflow
The CI/CD process is implemented as a multi-stage workflow within GitHub Actions:
    1. Commit & Push: A developer commits code and pushes it to the GitHub repository.
    2. Checkout: The GitHub Action runner checks out the repository code.
    3. Login: The workflow logs into the target registry (e.g., ghcr.io) using the secure GITHUB_TOKEN.
    4. Build & Test: The Dockerfile is used to build the image. Unit/Integration tests are run against the built image.
    5. Push: The final, tagged image is pushed to the designated Container Registry.


🛠️ Getting Started
Prerequisites
    • A GitHub Account.
    • A functional Dockerfile in the repository root.
    • A basic GitHub Actions Workflow File in the .github/workflows/ directory.

1. Configure Repository Secrets (If using Docker Hub)
If you intend to push to Docker Hub instead of GHCR, you must configure two repository secrets:
    1. DOCKER_USERNAME: Your Docker Hub username.
    2. DOCKER_PASSWORD: A Docker Hub Personal Access Token (PAT) with Read, Write, and Delete permissions.
(Note: If using GHCR, the default GITHUB_TOKEN is sufficient.)

2. Locate the Workflow File
The CI/CD pipeline is defined in the following YAML file:
    • .github/workflows/main.yml

3. Run and Verify
    1. Commit and push any change to the main branch of this repository.
    2. Navigate to the Actions tab on the GitHub repository to monitor the pipeline execution.
    3. Upon success, verify the new image tags in the Packages section of your GitHub repository (for GHCR) or on your Docker Hub profile.

🐋 Accessing the Built Images (GHCR Example)
To pull the container image locally, you can use the following commands:
    
    1. Log in to GHCR:
       Bash
       # Use your GitHub username and a Personal Access Token (PAT) with 'read:packages' scope
       docker login ghcr.io -u <GITHUB_USERNAME>
    
    2. Pull and Run the Container:
       Bash
       # Image name format: ghcr.io/<OWNER>/<REPOSITORY_NAME>:<TAG>
       IMAGE_NAME=ghcr.io/Hashbury1/ci-cd-docker-project:latest
       
       docker pull $IMAGE_NAME
       docker run -d -p 8080:8080 $IMAGE_NAME

❓ Troubleshooting
    • Authentication Failed (401/403 Error): Ensure your workflow is using the correct credentials. If pushing to GHCR, verify the workflow has the required permissions: write-packages defined.
    • Image Not Found in Registry: Check the logs to ensure the docker/build-push-action step was reached and executed the push: true flag.

🤝 Contribution
Contributions are welcome! Please open an issue or submit a pull request for any improvements, especially concerning testing automation within the pipeline.
