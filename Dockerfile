# Stage 1: Build Quartz site
FROM node:22-alpine AS builder

RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /usr/src/app

# Copy dependency manifests first for better layer caching
COPY site/package.json site/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

# Copy the Quartz source
COPY site/ .

# Copy vault content into site/content/
COPY vault/ ./content/

# Build
ARG PAGE_TITLE="Grove"
ARG BASE_URL="localhost"
ENV PAGE_TITLE=${PAGE_TITLE}
ENV BASE_URL=${BASE_URL}
RUN node quartz/bootstrap-cli.mjs build

# Stage 2: Serve with Nginx
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /usr/src/app/public /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
