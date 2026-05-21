#!/usr/bin/env bash
# deploy.sh — agentOS-angola — Google Cloud Run
#
# Uso:
#   chmod +x deploy.sh
#   ./deploy.sh                        # first-time setup + deploy
#   ./deploy.sh --deploy-only          # deploy sem reconfigurar a infra
#   ./deploy.sh --region us-central1   # substituir região
#
# Pré-requisitos:
#   - gcloud CLI instalado e autenticado  (gcloud auth login)
#   - Projecto GCP definido               (gcloud config set project <id>)
#   - .env preenchido (cópia de .env.example)
set -euo pipefail

# ── Configuração ──────────────────────────────────────────────────────────────
REGION="europe-west1"
SERVICE="agentOS-angola"
AR_REPO="agentOS-angola"
IMAGE="agentOS-angola"
SA_NAME="agentOS-angola-sa"
DEPLOY_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region)        REGION="$2";      shift 2 ;;
    --service)       SERVICE="$2";     shift 2 ;;
    --deploy-only)   DEPLOY_ONLY=true; shift   ;;
    *) echo "Opção desconhecida: $1"; exit 1 ;;
  esac
done

PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [[ -z "$PROJECT_ID" ]]; then
  echo "Erro: nenhum projecto GCP configurado."
  echo "  gcloud config set project <SEU_PROJECT_ID>"
  exit 1
fi

AR_IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO}/${IMAGE}"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "========================================================"
echo " agentOS-angola — deploy"
echo " Projecto : $PROJECT_ID"
echo " Região   : $REGION"
echo " Serviço  : $SERVICE"
echo " Imagem   : $AR_IMAGE"
echo "========================================================"

# ── Carregar .env ─────────────────────────────────────────────────────────────
if [[ ! -f .env ]]; then
  echo "Erro: ficheiro .env não encontrado. Cria-o a partir de .env.example."
  exit 1
fi
set -o allexport; source .env; set +o allexport

# ── 1. APIs ───────────────────────────────────────────────────────────────────
if [[ "$DEPLOY_ONLY" == false ]]; then
  echo ""
  echo "▶ 1/6  Activar APIs necessárias..."
  gcloud services enable \
    run.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    firestore.googleapis.com \
    firebase.googleapis.com \
    secretmanager.googleapis.com \
    iam.googleapis.com \
    --quiet

  # ── 2. Artifact Registry ─────────────────────────────────────────────────────
  echo ""
  echo "▶ 2/6  Repositório Artifact Registry..."
  if ! gcloud artifacts repositories describe "$AR_REPO" \
      --location="$REGION" --quiet &>/dev/null; then
    gcloud artifacts repositories create "$AR_REPO" \
      --repository-format=docker \
      --location="$REGION" \
      --description="agentOS-angola container images"
    echo "    Repositório criado: $AR_REPO"
  else
    echo "    Já existe: $AR_REPO"
  fi
  gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

  # ── 3. Service Account ───────────────────────────────────────────────────────
  echo ""
  echo "▶ 3/6  Service Account e IAM..."
  if ! gcloud iam service-accounts describe "$SA_EMAIL" --quiet &>/dev/null; then
    gcloud iam service-accounts create "$SA_NAME" \
      --display-name="agentOS-angola Cloud Run SA"
    echo "    Service account criada: $SA_EMAIL"
  else
    echo "    Já existe: $SA_EMAIL"
  fi

  for ROLE in \
    roles/datastore.user \
    roles/secretmanager.secretAccessor \
    roles/firebase.admin \
    roles/logging.logWriter \
    roles/cloudtrace.agent; do
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
      --member="serviceAccount:$SA_EMAIL" \
      --role="$ROLE" \
      --quiet &>/dev/null
    echo "    IAM: $ROLE → $SA_EMAIL"
  done

  # Permitir que o Cloud Build faça deploy no Cloud Run
  CB_SA="${PROJECT_ID}@cloudbuild.gserviceaccount.com"
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${CB_SA}" \
    --role="roles/run.admin" --quiet &>/dev/null
  gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
    --member="serviceAccount:${CB_SA}" \
    --role="roles/iam.serviceAccountUser" --quiet &>/dev/null

  # ── 4. Secrets no Secret Manager ────────────────────────────────────────────
  echo ""
  echo "▶ 4/6  Criar/actualizar secrets no Secret Manager..."

  _create_secret() {
    local NAME="$1"
    local VALUE="$2"
    if [[ -z "$VALUE" ]]; then
      echo "    AVISO: $NAME está vazio — secret não criado."
      return
    fi
    if ! gcloud secrets describe "$NAME" --quiet &>/dev/null; then
      echo -n "$VALUE" | gcloud secrets create "$NAME" \
        --data-file=- --replication-policy=automatic --quiet
      echo "    Criado: $NAME"
    else
      echo -n "$VALUE" | gcloud secrets versions add "$NAME" \
        --data-file=- --quiet
      echo "    Actualizado: $NAME"
    fi
  }

  _create_secret "openai-api-key"          "${OPENAI_API_KEY:-}"
  _create_secret "whatsapp-verify-token"   "${WHATSAPP_VERIFY_TOKEN:-}"
  _create_secret "whatsapp-app-secret"     "${WHATSAPP_APP_SECRET:-}"
  _create_secret "whatsapp-api-token"      "${WHATSAPP_API_TOKEN:-}"
  _create_secret "api-secret-key"          "${API_SECRET_KEY:-}"

  # ── 5. Firestore ─────────────────────────────────────────────────────────────
  echo ""
  echo "▶ 5/6  Firestore (base de dados nativa)..."
  if ! gcloud firestore databases describe --quiet &>/dev/null 2>&1; then
    gcloud firestore databases create \
      --location="${GCP_REGION:-$REGION}" \
      --type=firestore-native \
      --quiet || echo "    (base de dados já existe ou região não suportada)"
  else
    echo "    Já existe."
  fi

fi  # fim de --deploy-only

# ── 6. Build + Deploy ─────────────────────────────────────────────────────────
echo ""
echo "▶ 6/6  Build e deploy no Cloud Run..."

# Nota: --source usa o Dockerfile do directório actual via Cloud Build
# A flag correcta para env vars de ficheiro é --env-vars-file (formato YAML)
# Secrets sensíveis vêm do Secret Manager via --set-secrets
gcloud run deploy "$SERVICE" \
  --source . \
  --region "$REGION" \
  --platform managed \
  --allow-unauthenticated \
  --port 8080 \
  --min-instances 1 \
  --max-instances 10 \
  --concurrency 80 \
  --memory 1Gi \
  --cpu 1 \
  --timeout 60 \
  --service-account "$SA_EMAIL" \
  --set-env-vars "\
APP_ENV=production,\
LOG_LEVEL=INFO,\
GCP_PROJECT_ID=${PROJECT_ID},\
CHECKPOINTER_BACKEND=firestore,\
FIRESTORE_COLLECTION=agentos_checkpoints,\
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID:-$PROJECT_ID},\
ORCHESTRATOR_MODEL=${ORCHESTRATOR_MODEL:-gpt-4o},\
SUPPORT_MODEL=${SUPPORT_MODEL:-gpt-4o-mini},\
COMMERCIAL_MODEL=${COMMERCIAL_MODEL:-gpt-4o-mini},\
LEGAL_MODEL=${LEGAL_MODEL:-gpt-4o},\
HR_MODEL=${HR_MODEL:-gpt-4o-mini},\
FINANCIAL_MODEL=${FINANCIAL_MODEL:-gpt-4o},\
MARKETING_MODEL=${MARKETING_MODEL:-gpt-4o-mini},\
WHATSAPP_DEFAULT_TENANT=${WHATSAPP_DEFAULT_TENANT:-default},\
LANGCHAIN_TRACING_V2=false" \
  --set-secrets "\
OPENAI_API_KEY=openai-api-key:latest,\
WHATSAPP_VERIFY_TOKEN=whatsapp-verify-token:latest,\
WHATSAPP_APP_SECRET=whatsapp-app-secret:latest,\
WHATSAPP_API_TOKEN=whatsapp-api-token:latest,\
API_SECRET_KEY=api-secret-key:latest"

echo ""
echo "========================================================"
echo " Deploy concluído!"
SERVICE_URL=$(gcloud run services describe "$SERVICE" \
  --region "$REGION" --format "value(status.url)")
echo " URL : $SERVICE_URL"
echo " Health: $(curl -sf "${SERVICE_URL}/api/v1/health" || echo 'N/D')"
echo ""
echo " Configura o webhook WhatsApp:"
echo "   URL verificação : ${SERVICE_URL}/api/v1/webhook/whatsapp"
echo "   Verify token    : (ver Secret Manager → whatsapp-verify-token)"
echo "========================================================"
