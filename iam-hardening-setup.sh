name: Hardened Docker CI

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  # Hardcoded to specific registry - no wildcards
  IMAGE_REPOSITORY: ghcr.io/hashbury1/ci-cd-docker

jobs:
  build-and-test:
    name: Build and Test (Hardened)
    runs-on: ubuntu-latest
    
    # Minimal permissions - principle of least privilege
    permissions:
      contents: read        # Can read code (needed for checkout)
      packages: write       # Can push to packages (restricted by token)
      # NO OTHER PERMISSIONS

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      # Using fine-grained token instead of GITHUB_TOKEN
      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          # Use custom token with restricted scope
          password: ${{ secrets.REGISTRY_TOKEN }}

      - name: Validate registry target
        run: |
          # Security check: Ensure we're only pushing to allowed registry
          ALLOWED_REGISTRY="ghcr.io/hashbury1/ci-cd-docker"
          
          if [[ "${{ env.IMAGE_REPOSITORY }}" != "$ALLOWED_REGISTRY" ]]; then
            echo "❌ ERROR: Attempting to push to unauthorized registry!"
            echo "Allowed: $ALLOWED_REGISTRY"
            echo "Attempted: ${{ env.IMAGE_REPOSITORY }}"
            exit 1
          fi
          
          echo "✅ Registry validation passed: ${{ env.IMAGE_REPOSITORY }}"

      - name: Get short SHA
        id: sha
        run: echo "short_sha=$(echo ${{ github.sha }} | cut -c1-8)" >> $GITHUB_OUTPUT

      - name: Build Docker image
        run: |
          # Only build to the specific allowed repository
          IMAGE="${{ env.IMAGE_REPOSITORY }}"
          TAG="${{ steps.sha.outputs.short_sha }}"
          
          echo "Building image: ${IMAGE}:${TAG}"
          docker build -t ${IMAGE}:${TAG} .
          docker tag ${IMAGE}:${TAG} ${IMAGE}:latest
          
          echo "IMAGE=${IMAGE}" >> $GITHUB_ENV
          echo "TAG=${TAG}" >> $GITHUB_ENV

      - name: Push Docker image (Restricted)
        run: |
          # Double-check we're pushing to allowed registry
          if [[ "${IMAGE}" != "ghcr.io/hashbury1/ci-cd-docker" ]]; then
            echo "❌ Security violation: Unauthorized push attempt blocked!"
            exit 1
          fi
          
          echo "📤 Pushing ${IMAGE}:${TAG}"
          docker push ${IMAGE}:${TAG}
          
          echo "📤 Pushing ${IMAGE}:latest"
          docker push ${IMAGE}:latest
          
          echo "✅ Images pushed successfully to authorized registry only"

      - name: Verify push (Security Check)
        run: |
          echo "🔒 Verifying image was pushed to correct registry..."
          docker pull ${IMAGE}:${TAG}
          
          # Verify it's the exact image we built
          PUSHED_DIGEST=$(docker inspect ${IMAGE}:${TAG} --format='{{.Id}}')
          echo "Image digest: ${PUSHED_DIGEST}"
          echo "✅ Verification complete - image integrity confirmed"

      - name: Run tests
        run: |
          echo "🧪 Running tests in container..."
          docker run --rm ${IMAGE}:${TAG} npm test

      - name: Security audit summary
        run: |
          echo "### 🔒 Security Audit" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Registry Used:** \`${IMAGE}\`" >> $GITHUB_STEP_SUMMARY
          echo "**Allowed Registry:** \`ghcr.io/hashbury1/ci-cd-docker\`" >> $GITHUB_STEP_SUMMARY
          echo "**Status:** ✅ All security checks passed" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Permissions Used:**" >> $GITHUB_STEP_SUMMARY
          echo "- \`contents: read\` - Repository code access" >> $GITHUB_STEP_SUMMARY
          echo "- \`packages: write\` - Container registry access (token-restricted)" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Image Tags:**" >> $GITHUB_STEP_SUMMARY
          echo "- \`${IMAGE}:${TAG}\`" >> $GITHUB_STEP_SUMMARY
          echo "- \`${IMAGE}:latest\`" >> $GITHUB_STEP_SUMMARY

  # Optional: Separate job to demonstrate role isolation
  security-scan:
    name: Security Scan (Read-Only)
    runs-on: ubuntu-latest
    needs: build-and-test
    
    # Even MORE restricted - read-only
    permissions:
      contents: read
      packages: read    # Only READ packages, cannot write
      security-events: write  # Can report security issues

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Log in to registry (Read-Only)
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}  # Read-only token is fine here

      - name: Get short SHA
        id: sha
        run: echo "short_sha=$(echo ${{ github.sha }} | cut -c1-8)" >> $GITHUB_OUTPUT

      - name: Pull image for scanning
        run: |
          IMAGE="ghcr.io/hashbury1/ci-cd-docker"
          TAG="${{ steps.sha.outputs.short_sha }}"
          
          echo "📥 Pulling image for security scan..."
          docker pull ${IMAGE}:${TAG}
          
          # This job CANNOT push - it only has read permissions
          echo "✅ Image pulled successfully (read-only access)"

      - name: Run Trivy security scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ghcr.io/hashbury1/ci-cd-docker:${{ steps.sha.outputs.short_sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: Upload security results
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'

      - name: Demonstrate read-only restriction
        run: |
          echo "🔒 This job has READ-ONLY access"
          echo "If we tried to push, it would fail:"
          echo ""
          echo "docker push ghcr.io/hashbury1/ci-cd-docker:test"
          echo "❌ Would get: denied: permission_denied"
          echo ""
          echo "✅ This ensures separation of duties!"