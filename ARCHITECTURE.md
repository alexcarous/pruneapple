# System Architecture

## Overview
[A high-level summary of how the system works and its primary components.]

## Component Map
- **[Component A]**: [Description of its responsibility]
- **[Component B]**: [Description of its responsibility]

## Data Flow
1. [Step 1]: e.g., "User provides a prefix via CLI."
2. [Step 2]: e.g., "The system filters the raw TLD database using whitelist rules."
3. [Step 3]: e.g., "Heuristics score the remaining candidates."

## Key Design Decisions (ADRs)
- **[Decision 1]**: e.g., "Using RDAP over WHOIS as the primary check for better reliability."
- **[Decision 2]**: e.g., "Stateless design to ensure scalability."

## Security & Compliance
- [e.g., No sensitive data is stored locally.]
- [e.g., All external requests use HTTPS.]
