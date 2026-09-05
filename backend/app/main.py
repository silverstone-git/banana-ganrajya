import logging
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from app.api.routers.articles import router as articles_router

# Configure Python logging for detailed, verbose terminal output
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("banana-api")

app = FastAPI(
    title="Banana Ganrajya API",
    description="Robust backend services and data synchronization feeds for Banana Ganrajya journalistic application.",
    version="1.0.0"
)

# Custom HTTP request-response logging middleware for high-fidelity debugging
@app.middleware("http")
async def log_requests(request: Request, call_next):
    # Log HTTP Method and Path
    logger.info(f"--> [HTTP] {request.method} {request.url.path}")
    
    # Log non-sensitive headers (sanitize Authorization token for safe terminal prints)
    headers_to_log = {}
    for k, v in request.headers.items():
        if k.lower() == "authorization":
            # Show token type and length/truncated segments for debugging mismatch
            parts = v.split(" ")
            if len(parts) == 2:
                token_val = parts[1]
                segments = token_val.split(".")
                headers_to_log[k] = f"{parts[0]} (length: {len(token_val)}, segments: {len(segments)})"
            else:
                headers_to_log[k] = "Invalid Bearer Format"
        else:
            headers_to_log[k] = v
            
    logger.info(f"Headers: {headers_to_log}")
    
    # Consume request body safely (if applicable) and re-feed it to avoid blocking downstream handlers
    if request.method in ["POST", "PUT", "PATCH"]:
        body = await request.body()
        async def receive():
            return {"type": "http.request", "body": body, "more_body": False}
        request._receive = receive
        
        try:
            body_str = body.decode("utf-8")
            logger.info(f"Payload: {body_str[:1000]}")
        except Exception:
            logger.info("Payload: [binary or non-UTF-8 data]")
            
    response = await call_next(request)
    logger.info(f"<-- [HTTP] {response.status_code}")
    return response

# Set up explicit allowed origins. 
# Under CORS specifications, if 'allow_credentials' is set to True, the origin header 
# CANNOT use the wildcard "*" as it would introduce cross-origin session vulnerabilities.
allowed_origins = [
    "http://localhost",
    "http://localhost:8000",
    "http://localhost:3000",
    "http://127.0.0.1",
    "http://127.0.0.1:8000",
    "https://banana.aryan.cfd",  # Your production release domain
    "https://1253-2401-4900-1c5a-185b-615c-154c-1a34-a4d5.ngrok-free.app",  # Your active ngrok proxy URL
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {
        "app": "Banana Ganrajya API",
        "status": "online",
        "documentation": "/docs"
    }

app.include_router(articles_router)
