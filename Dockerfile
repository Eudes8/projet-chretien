# Use the official Node.js 18 image.
FROM node:18-alpine

# Create app directory
WORKDIR /app

# Copy package files and install dependencies
COPY backend-native/package*.json ./
RUN npm install --production

# Copy the rest of the backend code
COPY backend-native/ .

# Expose the port the app runs on
EXPOSE 3000

# Start the server
CMD ["node", "server.js"]
