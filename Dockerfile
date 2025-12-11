# Stage 1: Build Stage (Uses a specialized image to install dependencies)
# We use a slim version for a smaller final image size.
FROM node:20-alpine AS build

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json first. 
# This layer is cached unless dependencies change, speeding up subsequent builds.
COPY package*.json ./

# Install dependencies
# If your app runs unit tests, this is where dependencies are installed.
RUN npm install

# Copy the rest of the application source code
COPY . .

# Stage 2: Production Stage (Creates the final, minimal runtime image)
# This uses the smallest possible image that can still run Node.js.
FROM node:20-alpine AS production

WORKDIR /app

# Copy only the necessary files from the build stage
# This creates a "builder pattern" to keep the final image clean and small.
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package*.json ./
COPY . .

# Expose the port the app runs on (if it were a web server)
EXPOSE 3000

# Define the command to run when the container starts
# CRUCIAL: This line is just the final command. For tests, we use 'docker run' (Job 2).
CMD ["npm", "start"]