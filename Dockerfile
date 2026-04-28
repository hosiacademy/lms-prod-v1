FROM ghcr.io/cirruslabs/flutter:stable AS build-env

WORKDIR /app

RUN git config --global --add safe.directory /sdks/flutter

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .

RUN flutter build web --release --web-renderer canvaskit

FROM nginx:alpine AS final

COPY --from=build-env /app/build/web /usr/share/nginx/html

RUN chmod -R a+r /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
