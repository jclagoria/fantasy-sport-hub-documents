# Fantasy Sport Hub - Documentation

This repository contains documentation and Docker Compose configurations for the Fantasy Sport Hub platform.

## 📁 Repository Contents

- **`/docker`**: Docker Compose files for local development and deployment
- **`/architecture`**: Architecture decision records and diagrams
- **`/implementation`**: Detailed implementation guides and specifications
- **`/roadmap`**: Project roadmap and planning documents

## 🚀 Source Code Repositories

The main application code is organized in separate repositories:

### Backend

- **Repository**: [fantasysport-hub-backend](https://github.com/jclagoria/fantasy-sport-hub-backend.git)
- **Description**: Event-sourced backend service built with Java/Spring
- **Features**:
  - Event sourcing implementation
  - CQRS pattern
  - gRPC/HTTP APIs

### Frontend

- **Repository**: [fantasysport-hub-frontend](https://github.com/jclagoria/fantasy-sport-hub-frontend.git)
- **Description**: Modern web interface built with React/TypeScript
- **Features**:
  - Real-time updates
  - Responsive design
  - Interactive dashboards

## 🛠️ Development Setup

1. Clone this repository
2. Navigate to the `docker` directory
3. Run `docker-compose up -d` to start the required services
4. Follow the setup instructions in the respective backend/frontend repositories

## 📝 Documentation

- [Architecture Overview](./architecture/README.md)
- [API Documentation](./api/README.md)
- [Development Guidelines](./development/README.md)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.