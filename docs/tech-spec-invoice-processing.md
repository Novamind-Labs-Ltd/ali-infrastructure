# Technical Specification Document

## Invoice Processing Agent

**Document Version:** 1.1
**Date:** December 2025
**Authors:** Novamind Labs Engineering

---

## 1. System Overview

### 1.1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Invoice Processing System                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐    ┌───────────────────────────────────────────────────┐  │
│  │              │    │              invoice_processor/                    │  │
│  │   CLI        │───▶│  ┌─────────┐  ┌─────────┐  ┌──────────────────┐  │  │
│  │  (cli.py)    │    │  │ models  │  │  agent  │  │ markdown_generator│  │  │
│  │              │    │  │  .py    │  │  .py    │  │      .py          │  │  │
│  └──────────────┘    │  └────┬────┘  └────┬────┘  └────────┬─────────┘  │  │
│                      │       │            │                 │            │  │
│                      │       └────────────┼─────────────────┘            │  │
│                      │                    │                              │  │
│                      └────────────────────┼──────────────────────────────┘  │
│                                           │                                  │
│  ┌────────────────────────────────────────┼────────────────────────────────┐│
│  │                                        ▼                                ││
│  │  ┌─────────────────┐    ┌─────────────────────────────────────────┐    ││
│  │  │   Agno          │    │         LLM Providers (one of)          │    ││
│  │  │   Framework     │───▶├─────────────────────────────────────────┤    ││
│  │  │                 │    │ • Anthropic Claude  (default)           │    ││
│  │  │  Model Factory: │    │ • OpenAI GPT-4o                         │    ││
│  │  │  - Claude       │    │ • Azure OpenAI                          │    ││
│  │  │  - OpenAIChat   │    │ • OpenAI-Compatible (Ollama, LM Studio) │    ││
│  │  │  - AzureOpenAI  │    │ • Qwen VL (DashScope)                   │    ││
│  │  │  - OpenAILike   │    └─────────────────────────────────────────┘    ││
│  │  └─────────────────┘           External Services                        ││
│  └─────────────────────────────────────────────────────────────────────────┘│
│                                                                              │
│  ┌───────────────────┐                      ┌────────────────────────────┐  │
│  │   Input           │                      │   Output                   │  │
│  │   ─────           │                      │   ──────                   │  │
│  │   • PDF Files     │                      │   • Markdown Docs          │  │
│  │   • Directories   │                      │   • JSON Data              │  │
│  │                   │                      │   • Batch Index            │  │
│  └───────────────────┘                      └────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Technology Stack

| Layer | Technology | Version | Purpose |
|-------|------------|---------|---------|
| Runtime | Python | >=3.11 | Core language |
| Framework | Agno | >=1.0.0 | AI agent framework with multi-provider support |
| AI Models | Claude, GPT-4o, etc. | Various | PDF extraction (provider-specific) |
| Data Validation | Pydantic | >=2.0.0 | Schema validation |
| API Client | Anthropic SDK | >=0.40.0 | Claude API access |
| API Client | OpenAI SDK | >=1.0.0 | OpenAI/Azure/Compatible API access |
| PDF Processing | PyMuPDF (fitz) | >=1.24.0 | PDF to image conversion for providers without native PDF support |
| Async | asyncio | stdlib | Concurrent processing |
| CLI | argparse | stdlib | Command-line interface |

**Supported LLM Providers:**
| Provider | Agno Class | Default Model | Environment Variable | PDF Support |
|----------|------------|---------------|---------------------|-------------|
| Anthropic | `Claude` | claude-sonnet-4-20250514 | `ANTHROPIC_API_KEY` | Native PDF |
| OpenAI | `OpenAIChat` | gpt-4o | `OPENAI_API_KEY` | Native PDF |
| Azure OpenAI | `AzureOpenAI` | gpt-4o | `AZURE_OPENAI_API_KEY` | Native PDF |
| OpenAI-Compatible | `OpenAILike` | gpt-4o | `OPENAI_API_KEY` | Native PDF |
| Qwen | `OpenAILike` | qwen-vl-max | `DASHSCOPE_API_KEY` | PDF→Images* |

*Qwen VL via DashScope requires PDF-to-image conversion (see Section 2.2.5)

### 1.3 Directory Structure

```
invoice_processing/
├── invoice_processor/           # Main package
│   ├── __init__.py             # Package exports
│   ├── models.py               # Pydantic data models
│   ├── agent.py                # Agno agent implementation
│   ├── markdown_generator.py   # Markdown output generator
│   └── cli.py                  # CLI interface
├── docs/                       # Documentation
│   ├── BRD.md                  # Business Requirements
│   ├── PRD.md                  # Product Requirements
│   ├── TECHNICAL_SPEC.md       # This document
│   └── IMPLEMENTATION_TASKS.md # Implementation tasks
├── sample-invoices/            # Sample data
│   ├── Autopay Utility/
│   ├── IT/
│   ├── Rent/
│   └── ...
├── tests/                      # Test suite
├── example.py                  # Usage examples
├── pyproject.toml              # Project configuration
├── README.md                   # Project documentation
└── CLAUDE.md                   # AI assistant context
```

---

## 2. Component Specifications

### 2.1 Data Models (`models.py`)

#### 2.1.0 Provider Enum and Configuration

```python
from enum import Enum

class Provider(str, Enum):
    """Supported LLM providers."""
    ANTHROPIC = "anthropic"
    OPENAI = "openai"
    AZURE_OPENAI = "azure-openai"
    OPENAI_COMPATIBLE = "openai-compatible"
    QWEN = "qwen"

DEFAULT_MODELS: dict[str, str] = {
    Provider.ANTHROPIC: "claude-sonnet-4-20250514",
    Provider.OPENAI: "gpt-4o",
    Provider.AZURE_OPENAI: "gpt-4o",
    Provider.OPENAI_COMPATIBLE: "gpt-4o",
    Provider.QWEN: "qwen-vl-max",
}

PROVIDER_ENV_VARS: dict[str, str] = {
    Provider.ANTHROPIC: "ANTHROPIC_API_KEY",
    Provider.OPENAI: "OPENAI_API_KEY",
    Provider.AZURE_OPENAI: "AZURE_OPENAI_API_KEY",
    Provider.OPENAI_COMPATIBLE: "OPENAI_API_KEY",
    Provider.QWEN: "DASHSCOPE_API_KEY",
}

# Default base URLs for providers that need them
PROVIDER_BASE_URLS: dict[str, str] = {
    Provider.QWEN: "https://dashscope.aliyuncs.com/compatible-mode/v1",
}
```

#### 2.1.1 InvoiceMetadata

```python
class InvoiceMetadata(BaseModel):
    """Metadata about the PDF file itself."""

    file_name: str          # Original file name
    file_path: str          # Absolute path to file
    file_size_bytes: int    # File size in bytes
    page_count: Optional[int]  # Number of pages (if available)
    category: Optional[str]    # Derived from folder structure
    processed_at: str          # ISO timestamp
```

**Field Derivation:**
- `category`: Extracted from folder path by matching against known categories
- `processed_at`: Generated at processing time using `datetime.now().isoformat()`

#### 2.1.2 InvoiceData

```python
class InvoiceData(BaseModel):
    """Extracted invoice data fields."""

    # Core Fields (Import Template)
    vendor_name: Optional[str]
    invoice_number: Optional[str]
    invoice_date: Optional[str]      # YYYY-MM-DD format
    currency: Optional[str]          # ISO currency code
    amount: Optional[float]

    # Location & Allocation
    club_location: Optional[str]
    allocation_batch_no: Optional[str]

    # Expense Classification
    expense_type: Optional[str]      # Category enum
    expense_period: Optional[str]    # YYYY-MM format

    # Accounting Fields
    project: Optional[str]
    code: Optional[str]              # GL code
    amortisation_period: Optional[str]
    department_code: Optional[str]
    po_number: Optional[str]

    # Additional Fields
    due_date: Optional[str]
    payment_terms: Optional[str]
    tax_amount: Optional[float]
    subtotal: Optional[float]
    description: Optional[str]
    vendor_address: Optional[str]
    billing_address: Optional[str]
```

**Validation Rules:**
- All fields are optional to handle incomplete invoices
- Dates must be in YYYY-MM-DD format
- Amounts must be positive decimals
- Currency codes should be ISO 4217 compliant

#### 2.1.3 ProcessedInvoice

```python
class ProcessedInvoice(BaseModel):
    """Complete processed invoice result."""

    metadata: InvoiceMetadata
    summary: str                          # AI-generated summary
    invoice_data: InvoiceData
    supporting_hyperlink: Optional[str]   # file:// URL
    extraction_confidence: Optional[str]  # high/medium/low
    notes: Optional[str]                  # Additional observations
```

### 2.2 Agent Implementation (`agent.py`)

#### 2.2.1 InvoiceExtractionResult

Structured output schema for Claude extraction:

```python
class InvoiceExtractionResult(BaseModel):
    """Schema for AI extraction output."""

    summary: str                    # Required 2-3 sentence summary
    # ... all InvoiceData fields ...
    extraction_confidence: str      # Required confidence level
    notes: Optional[str]
```

#### 2.2.2 Extraction Instructions

The agent uses detailed extraction guidelines:

```python
EXTRACTION_INSTRUCTIONS = """
You are an expert invoice data extraction specialist...

## Extraction Guidelines:
1. Be Precise: Extract data exactly as it appears
2. Date Format: Convert to YYYY-MM-DD
3. Currency: Identify by symbol or explicit code
4. Amounts: Numeric without symbols
5. Expense Type: Categorize appropriately
6. Expense Period: Service period, not invoice date
7. Club Location: Location codes or site identifiers
8. Confidence Level:
   - High: All core fields clear
   - Medium: Most fields extracted, some ambiguity
   - Low: Significant missing data
9. Summary: Concise 2-3 sentences
10. Notes: Document extraction issues
"""
```

#### 2.2.3 InvoiceProcessorAgent Class

```python
from agno.models.anthropic import Claude
from agno.models.openai import OpenAIChat
from agno.models.azure import AzureOpenAI
from agno.models.openai.like import OpenAILike

class InvoiceProcessorAgent:
    def __init__(
        self,
        model_id: Optional[str] = None,  # Uses provider default if None
        provider: str = "anthropic",
        api_key: Optional[str] = None,
        base_url: Optional[str] = None,  # For OpenAI-compatible
        azure_endpoint: Optional[str] = None,  # For Azure OpenAI
        azure_deployment: Optional[str] = None,  # For Azure OpenAI
    ):
        """Initialize agent with selected provider and model."""
        self.provider = Provider(provider)
        self.model_id = model_id or DEFAULT_MODELS[self.provider]
        self.api_key = api_key or os.environ.get(PROVIDER_ENV_VARS[self.provider])

        model = self._create_model()
        self.agent = Agent(
            model=model,
            instructions=[EXTRACTION_INSTRUCTIONS],
            output_schema=InvoiceExtractionResult,
            markdown=True,
        )

    def _create_model(self) -> Union[Claude, OpenAIChat, AzureOpenAI, OpenAILike]:
        """Factory method to create the appropriate model instance."""
        if self.provider == Provider.ANTHROPIC:
            return Claude(id=self.model_id, api_key=self.api_key)
        elif self.provider == Provider.OPENAI:
            return OpenAIChat(id=self.model_id, api_key=self.api_key)
        elif self.provider == Provider.AZURE_OPENAI:
            return AzureOpenAI(
                id=self.model_id,
                api_key=self.api_key,
                azure_endpoint=self.azure_endpoint,
                azure_deployment=self.azure_deployment,
            )
        elif self.provider == Provider.OPENAI_COMPATIBLE:
            return OpenAILike(
                id=self.model_id,
                api_key=self.api_key,
                base_url=self.base_url,
            )

    def _get_file_metadata(self, pdf_path: Path) -> InvoiceMetadata:
        """Extract file metadata including category detection."""

    def _encode_pdf_base64(self, pdf_path: Path) -> str:
        """Encode PDF to base64 for API transmission."""

    def process_invoice(
        self,
        pdf_path: str | Path,
        additional_context: Optional[str] = None,
    ) -> ProcessedInvoice:
        """Synchronous invoice processing."""

    async def process_invoice_async(
        self,
        pdf_path: str | Path,
        additional_context: Optional[str] = None,
    ) -> ProcessedInvoice:
        """Asynchronous invoice processing."""
```

#### 2.2.4 PDF Processing Flow

```
1. Validate PDF file exists and is valid
2. Extract file metadata (size, category, etc.)
3. Check if provider requires image conversion (_requires_image_conversion())
4. If image conversion needed (e.g., Qwen):
   a. Convert PDF pages to PNG images using PyMuPDF
   b. Create Agno Image objects for each page
   c. Send via agent.run(prompt, images=[...])
5. Else (native PDF support):
   a. Create Agno File object with PDF path
   b. Send via agent.run(prompt, files=[File(filepath=pdf_path)])
6. Parse structured response from LLM
7. Build ProcessedInvoice object
8. Return result
```

#### 2.2.5 PDF-to-Image Conversion (for Qwen VL/DashScope)

Some LLM providers do not support native PDF file input. The DashScope API (Qwen VL) only accepts `image_url` content type, not `file`. To support these providers, the agent includes PDF-to-image conversion using PyMuPDF.

**Why Image Conversion is Needed:**
- DashScope API returns error: `Invalid value: file. Supported values are: 'text','image_url','video_url' and 'video'.`
- Vision-based approach preserves visual layout (tables, formatting, logos)
- Better for invoice processing than text-only RAG extraction

**Implementation:**

```python
import fitz  # PyMuPDF
from agno.media import Image

def _pdf_to_images(self, pdf_path: Path, dpi: int = 150) -> list[Image]:
    """Convert PDF pages to images for providers that don't support PDF files.

    Args:
        pdf_path: Path to the PDF file.
        dpi: Resolution for rendering (default 150 for good quality/size balance).

    Returns:
        List of Image objects, one per page.
    """
    images = []
    doc = fitz.open(pdf_path)

    for page_num in range(len(doc)):
        page = doc[page_num]
        # Render page to pixmap (image)
        mat = fitz.Matrix(dpi / 72, dpi / 72)  # 72 is the base PDF resolution
        pix = page.get_pixmap(matrix=mat)
        # Get PNG bytes
        png_bytes = pix.tobytes("png")
        # Create Agno Image from bytes
        images.append(Image(content=png_bytes, mime_type="image/png"))

    doc.close()
    return images

def _requires_image_conversion(self) -> bool:
    """Check if the provider requires PDF to be converted to images.

    Returns:
        True if provider doesn't support PDF files natively.
    """
    return self.provider == Provider.QWEN
```

**Processing Logic:**

```python
def process_invoice(self, pdf_path: str | Path, ...) -> ProcessedInvoice:
    # ... validation and metadata extraction ...

    if self._requires_image_conversion():
        # Convert PDF to images for providers that don't support PDF files
        images = self._pdf_to_images(pdf_path)
        response = self.agent.run(prompt, images=images)
    else:
        # Use PDF file directly for providers that support it
        response = self.agent.run(prompt, files=[File(filepath=pdf_path)])

    # ... parse response and build result ...
```

**DPI Settings:**
| DPI | Quality | Use Case |
|-----|---------|----------|
| 72 | Low | Fast processing, simple documents |
| 150 | Medium (default) | Good balance of quality and file size |
| 300 | High | High-quality documents, small text |

### 2.3 Markdown Generator (`markdown_generator.py`)

#### 2.3.1 MarkdownGenerator Class

```python
class MarkdownGenerator:
    def __init__(self, output_dir: Optional[str | Path] = None):
        """Initialize with output directory."""

    def _format_amount(
        self,
        amount: Optional[float],
        currency: Optional[str] = None
    ) -> str:
        """Format amount with currency (e.g., 'HKD 1,500.00')."""

    def _format_field(
        self,
        value: Optional[str],
        default: str = "N/A"
    ) -> str:
        """Format field with default for None."""

    def generate(self, invoice: ProcessedInvoice) -> str:
        """Generate Markdown content string."""

    def generate_to_file(
        self,
        invoice: ProcessedInvoice,
        filename: Optional[str] = None,
    ) -> Path:
        """Generate and save Markdown file."""

    def generate_batch_index(
        self,
        invoices: list[ProcessedInvoice],
        title: str = "Invoice Processing Report",
    ) -> str:
        """Generate batch summary index."""

    def generate_batch_index_to_file(
        self,
        invoices: list[ProcessedInvoice],
        filename: str = "index.md",
        title: str = "Invoice Processing Report",
    ) -> Path:
        """Generate and save batch index file."""
```

#### 2.3.2 Generated Document Structure

```markdown
# Invoice: {number}

**Processed:** {timestamp}
**Confidence:** {level}

---

## Summary
{ai_summary}

---

## File Metadata
| Property | Value |
|----------|-------|
| File Name | `{name}` |
| File Path | `{path}` |
| File Size | {size} bytes |
| Category | {category} |

---

## Extracted Invoice Data

### Core Invoice Fields
| Field | Value |
|-------|-------|
| **Vendor Name** | {value} |
| **Invoice Number** | {value} |
| **Invoice Date** | {value} |
| **Currency** | {value} |
| **Amount** | {formatted_amount} |

### Location & Allocation
{table}

### Expense Classification
{table}

### Project & Accounting
{table}

### Amount Breakdown
{table}

### Description
{text}

### Address Information
{vendor_address}
{billing_address}

---

## Supporting Document
[View Original PDF]({hyperlink})

---

## Notes
{notes}

---

## Data Export (Import Template Format)
```yaml
vendor_name: {value}
invoice_number: {value}
...
```
```

### 2.4 CLI Interface (`cli.py`)

#### 2.4.1 Command Structure

```python
def main():
    parser = argparse.ArgumentParser(
        description="Process invoice PDFs and extract structured data"
    )

    parser.add_argument("input", help="PDF file or directory")
    parser.add_argument("-o", "--output", help="Output directory")
    parser.add_argument("-p", "--provider", default="anthropic",
                        choices=["anthropic", "openai", "azure-openai", "openai-compatible", "qwen"])
    parser.add_argument("-m", "--model", default=None)  # Uses provider default
    parser.add_argument("--api-key", help="API key (overrides env var)")
    parser.add_argument("--base-url", help="Base URL for OpenAI-compatible API")
    parser.add_argument("--azure-endpoint", help="Azure OpenAI endpoint URL")
    parser.add_argument("--azure-deployment", help="Azure OpenAI deployment name")
    parser.add_argument("-v", "--verbose", action="store_true")
    parser.add_argument("--async", dest="use_async", action="store_true")
    parser.add_argument("--concurrency", type=int, default=3)
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--no-recursive", action="store_true")
```

#### 2.4.2 Processing Functions

```python
def find_pdfs(directory: Path, recursive: bool = True) -> list[Path]:
    """Find PDF files in directory."""

def process_single(
    pdf_path: str,
    output_dir: Optional[str] = None,
    model_id: Optional[str] = None,
    provider: str = "anthropic",
    api_key: Optional[str] = None,
    base_url: Optional[str] = None,
    azure_endpoint: Optional[str] = None,
    azure_deployment: Optional[str] = None,
    verbose: bool = False,
) -> ProcessedInvoice:
    """Process single invoice synchronously."""

async def process_batch_async(
    pdf_paths: list[Path],
    output_dir: Optional[str] = None,
    model_id: Optional[str] = None,
    provider: str = "anthropic",
    api_key: Optional[str] = None,
    base_url: Optional[str] = None,
    azure_endpoint: Optional[str] = None,
    azure_deployment: Optional[str] = None,
    verbose: bool = False,
    concurrency: int = 3,
) -> list[ProcessedInvoice]:
    """Process multiple invoices concurrently."""

def process_batch(
    pdf_paths: list[Path],
    output_dir: Optional[str] = None,
    model_id: Optional[str] = None,
    provider: str = "anthropic",
    api_key: Optional[str] = None,
    base_url: Optional[str] = None,
    azure_endpoint: Optional[str] = None,
    azure_deployment: Optional[str] = None,
    verbose: bool = False,
) -> list[ProcessedInvoice]:
    """Process multiple invoices sequentially."""
```

---

## 3. API Specifications

### 3.1 LLM Provider APIs

The system supports multiple LLM providers, each with their own API format. The Agno framework abstracts these differences, but understanding the underlying APIs is useful for debugging and configuration.

#### 3.1.0 Provider Selection

```python
# Provider resolution order:
# 1. Explicit provider parameter
# 2. Default: "anthropic"

# API key resolution order:
# 1. Explicit api_key parameter
# 2. Provider-specific environment variable
#    - ANTHROPIC_API_KEY for anthropic
#    - OPENAI_API_KEY for openai/openai-compatible
#    - AZURE_OPENAI_API_KEY for azure-openai
```

### 3.2 Anthropic Claude API

#### 3.2.1 Request Format

```json
{
  "model": "claude-sonnet-4-20250514",
  "max_tokens": 4096,
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "document",
          "source": {
            "type": "base64",
            "media_type": "application/pdf",
            "data": "<base64_encoded_pdf>"
          }
        },
        {
          "type": "text",
          "text": "Please analyze this invoice PDF..."
        }
      ]
    }
  ]
}
```

#### 3.2.2 Response Format (Structured Output)

```json
{
  "content": [
    {
      "type": "text",
      "text": "{\"summary\": \"...\", \"vendor_name\": \"...\", ...}"
    }
  ],
  "model": "claude-sonnet-4-20250514",
  "usage": {
    "input_tokens": 1500,
    "output_tokens": 500
  }
}
```

### 3.3 Python API

#### 3.3.1 Public Interface

```python
from invoice_processor import (
    InvoiceProcessorAgent,
    MarkdownGenerator,
    ProcessedInvoice,
    InvoiceData,
    InvoiceMetadata,
    Provider,
)

# Anthropic Claude (default)
agent = InvoiceProcessorAgent()

# OpenAI GPT-4o
agent = InvoiceProcessorAgent(provider="openai", model_id="gpt-4o")

# Azure OpenAI
agent = InvoiceProcessorAgent(
    provider="azure-openai",
    model_id="gpt-4o",
    azure_endpoint="https://your-resource.openai.azure.com",
    azure_deployment="your-deployment",
)

# OpenAI-Compatible (Ollama)
agent = InvoiceProcessorAgent(
    provider="openai-compatible",
    model_id="llama3.2-vision",
    base_url="http://localhost:11434/v1",
)

# Qwen VL (DashScope)
agent = InvoiceProcessorAgent(
    provider="qwen",
    model_id="qwen-vl-max",
)

# Process invoice
result: ProcessedInvoice = agent.process_invoice("invoice.pdf")

# Async processing
result = await agent.process_invoice_async("invoice.pdf")

# Generate Markdown
generator = MarkdownGenerator("./output")
md_path = generator.generate_to_file(result)
```

---

## 4. Data Flow

### 4.1 Single Invoice Processing

```
┌────────────────┐
│   PDF File     │
│   (Input)      │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Validate File  │──▶ FileNotFoundError / ValueError
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Extract        │
│ Metadata       │──▶ InvoiceMetadata
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Encode PDF     │
│ (Base64)       │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Build Prompt   │
│ + Context      │
└───────┬────────┘
        │
        ▼
┌────────────────┐     ┌────────────────┐
│ Agno Agent     │────▶│ Claude API     │
│ (with schema)  │◀────│ (Extraction)   │
└───────┬────────┘     └────────────────┘
        │
        ▼
┌────────────────┐
│ Parse          │
│ Response       │──▶ InvoiceExtractionResult
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Build          │
│ ProcessedInvoice│──▶ ProcessedInvoice
└───────┬────────┘
        │
        ├──────────────────────────────────┐
        ▼                                  ▼
┌────────────────┐               ┌────────────────┐
│ Return Object  │               │ Generate       │
│ (JSON output)  │               │ Markdown       │
└────────────────┘               └────────────────┘
```

### 4.2 Batch Processing (Async)

```
┌────────────────┐
│ Directory      │
│ (Input)        │
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Find PDFs      │
│ (Glob)         │──▶ list[Path]
└───────┬────────┘
        │
        ▼
┌────────────────┐
│ Create         │
│ Semaphore(N)   │
└───────┬────────┘
        │
        ▼
┌────────────────────────────────────────────────┐
│                 asyncio.gather                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ PDF 1    │  │ PDF 2    │  │ PDF 3    │ ... │
│  │ Process  │  │ Process  │  │ Process  │     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘     │
│       │             │             │            │
│       └─────────────┼─────────────┘            │
│                     │                          │
└─────────────────────┼──────────────────────────┘
                      │
                      ▼
               ┌────────────────┐
               │ Collect        │
               │ Results        │──▶ list[ProcessedInvoice]
               └───────┬────────┘
                       │
                       ├──────────────────────────┐
                       ▼                          ▼
               ┌────────────────┐        ┌────────────────┐
               │ Generate       │        │ Generate       │
               │ Individual MDs │        │ Batch Index    │
               └────────────────┘        └────────────────┘
```

---

## 5. Error Handling

### 5.1 Error Categories

| Category | Exception | Handling |
|----------|-----------|----------|
| File I/O | `FileNotFoundError` | Log error, skip file |
| Validation | `ValueError` | Log error, skip file |
| API | `anthropic.APIError` | Retry with backoff |
| Rate Limit | `anthropic.RateLimitError` | Exponential backoff |
| Auth | `anthropic.AuthenticationError` | Fail immediately |
| Parsing | `pydantic.ValidationError` | Log error, return partial |

### 5.2 Error Recovery Strategy

```python
async def process_one(pdf_path: Path) -> Optional[ProcessedInvoice]:
    async with semaphore:
        try:
            result = await agent.process_invoice_async(pdf_path)
            return result
        except FileNotFoundError as e:
            print(f"✗ {pdf_path.name}: File not found", file=sys.stderr)
            return None
        except ValueError as e:
            print(f"✗ {pdf_path.name}: {e}", file=sys.stderr)
            return None
        except Exception as e:
            print(f"✗ {pdf_path.name}: Unexpected error: {e}", file=sys.stderr)
            return None

# Filter out None results
results = [r for r in completed if r is not None]
```

### 5.3 Retry Logic (Future Enhancement)

```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=60)
)
async def call_claude_with_retry(messages):
    return await agent.arun(messages=messages)
```

---

## 6. Security Considerations

### 6.1 API Key Management

```python
# Priority order for API key resolution:
# 1. Explicit api_key parameter
# 2. Provider-specific environment variable

class InvoiceProcessorAgent:
    def __init__(
        self,
        provider: str = "anthropic",
        api_key: Optional[str] = None,
    ):
        self.provider = Provider(provider)
        self.api_key = api_key or os.environ.get(PROVIDER_ENV_VARS[self.provider])
        # Note: API key validation is done by the provider SDK
```

**Provider Environment Variables:**
| Provider | Environment Variable |
|----------|---------------------|
| `anthropic` | `ANTHROPIC_API_KEY` |
| `openai` | `OPENAI_API_KEY` |
| `azure-openai` | `AZURE_OPENAI_API_KEY` |
| `openai-compatible` | `OPENAI_API_KEY` |
| `qwen` | `DASHSCOPE_API_KEY` |

**Azure OpenAI Additional Variables:**
- `AZURE_OPENAI_ENDPOINT` - Azure resource endpoint URL
- `AZURE_OPENAI_DEPLOYMENT` - Deployment name

### 6.2 Data Privacy

| Concern | Mitigation |
|---------|------------|
| PDF content sent to API | Use Anthropic's data privacy policy |
| Local file access | Standard file permissions |
| Output files | Standard file permissions |
| Sensitive data in invoices | User responsibility, no persistence |

### 6.3 Input Validation

```python
def process_invoice(self, pdf_path: str | Path):
    pdf_path = Path(pdf_path)

    # Validate existence
    if not pdf_path.exists():
        raise FileNotFoundError(f"PDF file not found: {pdf_path}")

    # Validate file type
    if not pdf_path.suffix.lower() == ".pdf":
        raise ValueError(f"File must be a PDF: {pdf_path}")

    # Validate file size (optional)
    if pdf_path.stat().st_size > 50 * 1024 * 1024:  # 50MB
        raise ValueError(f"PDF file too large: {pdf_path}")
```

---

## 7. Performance Optimization

### 7.1 Async Processing

```python
# Semaphore limits concurrent API calls
semaphore = asyncio.Semaphore(concurrency)

async def process_one(pdf_path: Path):
    async with semaphore:
        return await agent.process_invoice_async(pdf_path)

# Process all concurrently within limit
results = await asyncio.gather(*[process_one(p) for p in pdf_paths])
```

### 7.2 Performance Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Single invoice | < 30s | End-to-end time |
| Batch (10 invoices) | < 2 min | With concurrency=5 |
| Memory usage | < 500MB | Peak during batch |
| API latency | ~5-15s | Claude processing time |

### 7.3 Optimization Opportunities

1. **Caching**: Cache repeated vendor extractions
2. **Streaming**: Stream results as they complete
3. **Batching**: Batch small PDFs in single requests
4. **Compression**: Compress base64 payloads

---

## 8. Testing Strategy

### 8.1 Test Categories

| Category | Purpose | Tools |
|----------|---------|-------|
| Unit Tests | Test individual functions | pytest |
| Integration Tests | Test API integration | pytest + mocks |
| E2E Tests | Full workflow tests | pytest + sample PDFs |

### 8.2 Test Structure

```
tests/
├── __init__.py
├── conftest.py              # Fixtures
├── test_models.py           # Data model tests
├── test_agent.py            # Agent tests
├── test_markdown_generator.py
├── test_cli.py              # CLI tests
└── fixtures/
    ├── sample_invoice.pdf
    └── sample_response.json
```

### 8.3 Example Tests

```python
# test_models.py
def test_invoice_data_optional_fields():
    """All fields should be optional."""
    data = InvoiceData()
    assert data.vendor_name is None
    assert data.amount is None

def test_processed_invoice_serialization():
    """Should serialize to JSON."""
    invoice = ProcessedInvoice(
        metadata=InvoiceMetadata(...),
        summary="Test summary",
        invoice_data=InvoiceData(),
    )
    json_str = invoice.model_dump_json()
    assert "summary" in json_str
```

---

## 9. Deployment

### 9.1 Installation

```bash
# Clone repository
git clone https://github.com/novamind-labs/invoice_processing.git
cd invoice_processing

# Install with uv (recommended)
uv pip install -e .

# Or with pip
pip install -e .

# Set API key
export ANTHROPIC_API_KEY="sk-ant-..."
```

### 9.2 Dependencies

```toml
# pyproject.toml
[project]
requires-python = ">=3.11"
dependencies = [
    "agno>=1.0.0",
    "anthropic>=0.40.0",
    "openai>=1.0.0",
    "pydantic>=2.0.0",
    "pymupdf>=1.24.0",  # PDF to image conversion for Qwen VL
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.24.0",
    "ruff>=0.8.0",
]
```

### 9.3 Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | For anthropic provider | Claude API key |
| `OPENAI_API_KEY` | For openai/openai-compatible | OpenAI API key |
| `AZURE_OPENAI_API_KEY` | For azure-openai | Azure OpenAI API key |
| `AZURE_OPENAI_ENDPOINT` | For azure-openai | Azure resource endpoint URL |
| `AZURE_OPENAI_DEPLOYMENT` | For azure-openai | Azure deployment name |
| `DASHSCOPE_API_KEY` | For qwen provider | DashScope API key for Qwen VL |

---

## 10. Monitoring & Logging

### 10.1 Logging Strategy (Future)

```python
import logging

logger = logging.getLogger("invoice_processor")

# Log levels:
# DEBUG: Detailed extraction steps
# INFO: Processing progress
# WARNING: Low confidence extractions
# ERROR: Processing failures
```

### 10.2 Metrics to Track

| Metric | Type | Purpose |
|--------|------|---------|
| `invoices_processed` | Counter | Total processed |
| `processing_time_seconds` | Histogram | Latency distribution |
| `extraction_confidence` | Counter by level | Quality tracking |
| `api_errors` | Counter | Error rate |

---

## 11. Future Enhancements

### 11.1 Phase 2 Features

- [ ] Web interface (Flask/FastAPI)
- [ ] Database storage (SQLite/PostgreSQL)
- [ ] API server mode
- [ ] Webhook notifications
- [ ] Custom field mapping configuration

### 11.2 Phase 3 Features

- [ ] PO matching integration
- [ ] Approval workflow
- [ ] ERP system connectors
- [ ] Multi-language support
- [ ] OCR enhancement for scanned documents

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 2025 | Novamind Labs | Initial specification |
| 1.1 | Dec 2025 | Novamind Labs | Added multi-provider LLM support (OpenAI, Azure OpenAI, OpenAI-compatible) |
| 1.2 | Dec 2025 | Novamind Labs | Added Qwen VL provider support via DashScope API |
| 1.3 | Dec 2025 | Novamind Labs | Added PDF-to-image conversion for providers without native PDF support (PyMuPDF) |