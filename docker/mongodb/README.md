# MongoDB Setup for Fantasy Sports Hub

This guide will help you set up MongoDB with Docker for the Fantasy Sports Hub project.

## Prerequisites

- Docker and Docker Compose installed on your system
- Git (for cloning the repository)

## Setup Instructions

### 1. Clone the Repository (if not already done)

```bash
git clone <repository-url>
cd fantasysport-hub-project/docker/mongodb
```

### 2. Environment Configuration

Edit the `.env` file to set your preferred credentials and ports:

```bash
nano .env
```

### 3. Start MongoDB and MongoDB Express

Run the following command to start the MongoDB and MongoDB Express containers:

```bash
docker-compose -f docker-compose-mongodb.yml up -d
```

This will:
- Pull the required Docker images (if not already present)
- Create a MongoDB container with the specified configuration
- Create a MongoDB Express container for web-based administration
- Set up the network between containers

### 4. Verify the Setup

Check that the containers are running:

```bash
docker ps
```

You should see both `mongodb-mongo-1` and `mongodb-mongo-express-1` containers running.

### 5. Access MongoDB Express

Open your web browser and navigate to:
[http://localhost:8081](http://localhost:8081)

Login with the following credentials:
- **Username:** `mongoexpressuser`
- **Password:** `mongoexpresspass`

### 6. Verify Database Initialization

The initialization script should have already created the `fantasy_sports_hub` database with the following collections:
- `match_projections`
- `team_week_projections`
- `player_stats`
- `league_standings`
- `transaction_audit`
- `user_activity`
- `system_metrics`

To verify from the command line:

```bash
# List all databases
docker exec mongodb-mongo-1 mongosh -u root -p example123 --eval "db.adminCommand('listDatabases')"

# List collections in fantasy_sports_hub
docker exec mongodb-mongo-1 mongosh -u root -p example123 --eval "db.getSiblingDB('fantasy_sports_hub').getCollectionNames()"
```

## Connection Details

- **MongoDB Connection String:** `mongodb://root:example123@localhost:27017/fantasy_sports_hub`
- **MongoDB Express URL:** [http://localhost:8081](http://localhost:8081)
- **Default Credentials:**
  - MongoDB Admin: root/example123
  - MongoDB Express: mongoexpressuser/mongoexpresspass

## Stopping the Services

To stop the containers:

```bash
docker-compose -f docker-compose-mongodb.yml down
```

## Troubleshooting

### If the database isn't initialized:

1. Check the MongoDB container logs:
   ```bash
   docker logs mongodb-mongo-1
   ```

2. Manually run the initialization script:
   ```bash
   chmod +x run-mongodb-init.sh
   source .env && ./run-mongodb-init.sh
   ```

### If you can't connect to MongoDB Express:

1. Verify the container is running:
   ```bash
   docker ps
   ```

2. Check the logs for errors:
   ```bash
   docker logs mongodb-mongo-express-1
   ```

## Security Notes

- Change the default credentials in the `.env` file for production use
- Don't expose the MongoDB port (27017) to the internet
- Use proper network security groups and firewalls in production environments
