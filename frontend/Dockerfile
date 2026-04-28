FROM nginx:alpine
COPY prebuilt_web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN chmod -R a+r /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
