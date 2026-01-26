# Use official Dart image
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Copy app source code.
COPY . .

# Ensure packages are still there.
RUN dart pub get --offline

# Compile a self-contained executable.
RUN dart compile exe server.dart -o server

# Build a minimal docker image.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/bin/

# Start server.
EXPOSE 8080
CMD ["/app/bin/server"]
