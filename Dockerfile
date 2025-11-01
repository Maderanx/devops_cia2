# Use Node.js base image
FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies (production only)
RUN npm ci --only=production

# Copy the rest of the app source code
COPY . .

# Expose port 8080 for ECS
EXPOSE 8080

# Start the app
CMD ["npm", "start"]
