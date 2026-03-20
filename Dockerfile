FROM nginx:alpine

# Copy your app
COPY dist/ /usr/share/nginx/html/

# Override nginx config to listen on port 3000
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]
