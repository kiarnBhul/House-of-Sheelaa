FROM node:20-alpine

# Create app directory
WORKDIR /usr/src/app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Bundle app source
COPY . .

# Expose port (adjust if your server listens to a different port)
EXPOSE 3000

# Use an unprivileged user
RUN addgroup -S app && adduser -S app -G app
USER app

CMD ["node", "server.js"]
