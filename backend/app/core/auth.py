from fastapi_plugin import Auth0FastAPI
from app.core.config import settings

# If no dedicated API audience is configured, Auth0 defaults to validating 
# tokens against the Client ID for native application credentials.
audience = settings.AUTH0_AUDIENCE if settings.AUTH0_AUDIENCE else settings.AUTH0_CLIENT_ID

auth0 = Auth0FastAPI(
    domain=settings.AUTH0_DOMAIN,
    audience=audience,
)
