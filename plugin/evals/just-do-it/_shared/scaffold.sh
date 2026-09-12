#!/bin/bash
# Generates a minimal Abacus-like codebase skeleton for eval cases.
# Self-contained: no external paths, no local machine dependencies.

mkdir -p abacus/{models,core/auth,alembic/versions,adapters,routes,templates,tests,docs/adr}

cat > abacus/AGENTS.md << 'EOF'
# Abacus

Task tracker. Python 3.12 (FastAPI, async SQLAlchemy 2.0, Alembic, Pydantic v2)
managed with Poetry; Postgres; server-rendered Jinja templates with Alpine.js;
Tailwind CSS 3.4; Docker Compose.

Models live in `models/`. Routes live in `routes/`. Migrations in `alembic/versions/`.
EOF

cat > abacus/docker-compose.yml << 'EOF'
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: abacus
      POSTGRES_PASSWORD: dev
    ports: ["5432:5432"]
  app:
    build: .
    depends_on: [db]
    ports: ["8000:8000"]
EOF

cat > abacus/alembic.ini << 'EOF'
[alembic]
script_location = alembic
sqlalchemy.url = postgresql+asyncpg://postgres:dev@db/abacus
EOF

cat > abacus/models/__init__.py << 'EOF'
from .organization import Organization
from .ticket import Ticket
from .comment import Comment
EOF

cat > abacus/models/organization.py << 'EOF'
from sqlalchemy import Column, String, DateTime
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass

class Organization(Base):
    __tablename__ = "organizations"
    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False)
    settings = Column(String, default="{}")
EOF

cat > abacus/models/ticket.py << 'EOF'
from sqlalchemy import Column, String, DateTime, ForeignKey, Text
from .organization import Base

class Ticket(Base):
    __tablename__ = "tickets"
    id = Column(String, primary_key=True)
    key = Column(String, unique=True, nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, default="")
    type = Column(String, nullable=False)
    organization_id = Column(String, ForeignKey("organizations.id"), nullable=False)
    created_at = Column(DateTime, nullable=False)
EOF

cat > abacus/models/comment.py << 'EOF'
from sqlalchemy import Column, String, DateTime, ForeignKey, Text
from .organization import Base

class Comment(Base):
    __tablename__ = "comments"
    id = Column(String, primary_key=True)
    ticket_id = Column(String, ForeignKey("tickets.id"), nullable=False)
    body = Column(Text, nullable=False)
    author_id = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False)
EOF

cat > abacus/routes/__init__.py << 'EOF'
EOF

cat > abacus/routes/tickets.py << 'EOF'
from fastapi import APIRouter, Depends
router = APIRouter(prefix="/api/v1/tickets")

@router.get("/")
async def list_tickets():
    return {"tickets": []}

@router.get("/{key}")
async def get_ticket(key: str):
    return {"ticket": None}
EOF

cat > abacus/routes/projects.py << 'EOF'
from fastapi import APIRouter
router = APIRouter(prefix="/api/v1/projects")

@router.get("/")
async def list_projects():
    return {"projects": []}
EOF

cat > abacus/core/__init__.py << 'EOF'
EOF

cat > abacus/core/database.py << 'EOF'
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
DATABASE_URL = "postgresql+asyncpg://postgres:dev@db/abacus"
engine = create_async_engine(DATABASE_URL)
EOF

cat > abacus/core/permissions.py << 'EOF'
ROLES = ["admin", "member", "viewer"]

def check_permission(user, action, resource):
    if user.role == "admin":
        return True
    return False
EOF

cat > abacus/alembic/versions/20260724_2100_initial_schema.py << 'EOF'
"""initial schema"""
revision = "0001"
down_revision = None

def upgrade():
    pass

def downgrade():
    pass
EOF

cat > abacus/tests/__init__.py << 'EOF'
EOF

cat > abacus/tests/test_tickets.py << 'EOF'
def test_list_tickets():
    pass
EOF

cat > abacus/Makefile << 'EOF'
up:
	docker compose up -d

down:
	docker compose down

preflight:
	poetry run pytest
	poetry run ruff check .
EOF
