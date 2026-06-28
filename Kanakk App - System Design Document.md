# **Kanakk App: Production-Grade Custom Expense Tracker System Design**

**Version:** 1.0.0  
**Date:** June 28, 2026  
**Authors:** Dev Team

## **1\. Requirements Specification**

### **1.1 Functional Requirements**

- **Authentication & Identity:** Users must register and log in uniquely using their email address. Authentication must be verified securely via a One-Time Password (OTP) sent to the email. No traditional passwords.
- **Wallet Architecture:** There is no concept of a fixed monthly allowance. The user profile maintains a dynamic wallet balance. Every incoming transaction marked as INCOME (e.g., allowances from home, side payouts) directly increments the wallet balance.
- **Transaction Management:** Users can quickly log transactions by explicitly declaring them as an INCOME or an EXPENSE. Expenses must require a system or user-defined category (e.g., Food, Rent & Bills, Stationery, Grocery, Books & Utensils, Travel, Entertainment, Donation).
- **Dynamic & Open-Ended Budgeting:** Users can initialize a budget with a defined target amount and an explicit start date. The end date is left open-ended. A user can explicitly close a budget timeline at any moment, cementing the end-date and allowing a new budget window to start. Analytics must compute pacing against the active budget dynamically.
- **Custom Group Split Allocation:** A user can initiate a group split expense from a shared living pool. The split creator can select specific participants from the group and assign **custom individual amounts** to each person, mimicking the granular Google Pay split function rather than forcing equal distribution.
- **Split Acceptance Queue Workflow:** When an individual is included in a group split, the split expense is queued into their account as a "Pending Split Request". The amount does not alter their personal dashboard or wallet metrics until they explicitly view and accept the split. Upon acceptance, it is logged into their personal transaction history as a verified expense.
- **Data Portability & Reporting:** Users can export their financial ledgers (containing combined income, personal expenses, and accepted split values) as a high-fidelity PDF report or Excel spreadsheet across an arbitrary date range filter.

### **1.2 Non-Functional Requirements**

- **Data Integrity & Cloud Synchronization:** Architecture must prioritize an offline-first cache strategy or robust network retry policies to ensure transactional data is never dropped. Cloud synchronization must be real-time or securely batched.
- **Scalability:** The platform must support production-grade workloads for the core group of internal users immediately, with a clean structural separation to scale horizontally when opened to wider college cohorts.
- **Security:** All transactional modifications must be authorized server-side via JSON Web Tokens (JWT) linked to the verified email identity. Database Row-Level Security (RLS) is strict.

## ---

**2\. System Architecture & Technology Stack**

To achieve an extensible, robust, production-grade system, the platform uses a decoupled client-server architecture leveraging a modern backend-as-a-service layer augmented by an application backend for processing resource-heavy operations like PDF/Excel generation and automated email OTP workflows.

| Layer                   | Technology Selected   | Rationale & Architectural Responsibility                                                                                                                                                             |
| :---------------------- | :-------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Frontend Mobile App** | Flutter (Dart)        | Cross-platform consistency. Layered clean architecture design utilizing Riverpod for predictable unidirectional state management and dependency injection.                                           |
| **Local Caching Store** | Isar Database         | An ultra-fast, relational-compliant NoSQL local cache for Flutter. Ideal for offline tracking, instant UI loading, and subsequent syncing to the cloud.                                              |
| **Backend Engine & DB** | Supabase (PostgreSQL) | Provides a production-grade relational database natively supporting complex transactional joins (critical for split logic), built-in Go True Email OTP auth, and instantaneous real-time WebSockets. |
| **Application Server**  | FastAPI (Python)      | A high-performance asynchronous API framework utilized to process resource-intensive document generations (Pandas/ReportLab for Excel and PDF extraction) and custom complex business validations.   |

## ---

**3\. Relational Data Model (Database Schema)**

The system utilizes a relational PostgreSQL engine to guarantee ACID compliance for financial tracking. Below are the definitive structural properties and relations assigned to the entities.

### **3.1 Entity Attributes**

#### **Table: profiles**

- id (UUID, Primary Key \-\> References auth.users.id from Supabase Auth)
- email (VARCHAR, Unique, Indexed)
- display_name (VARCHAR)
- wallet_balance (NUMERIC(12, 2), Default: 0.00)
- created_at (TIMESTAMPTZ)

#### **Table: categories**

- id (UUID, Primary Key)
- user_id (UUID, Nullable \-\> Null represents global default categories; a specific UUID signifies a custom user-defined category)
- name (VARCHAR, e.g., 'Food', 'Rent & Bills', 'Travel')
- is_system_default (BOOLEAN, Default: TRUE)

#### **Table: personal_transactions**

- id (UUID, Primary Key)
- user_id (UUID, Foreign Key \-\> profiles.id, Indexed)
- category_id (UUID, Foreign Key \-\> categories.id, Nullable if transaction type is INCOME)
- type (VARCHAR, Constraint: CHECK (type IN ('INCOME', 'EXPENSE')))
- amount (NUMERIC(12, 2))
- description (TEXT, Nullable)
- transaction_date (TIMESTAMPTZ, Default: NOW())
- group_split_item_id (UUID, Foreign Key \-\> group_split_items.id, Nullable)

#### **Table: budgets**

- id (UUID, Primary Key)
- user_id (UUID, Foreign Key \-\> profiles.id, Indexed)
- target_amount (NUMERIC(12, 2))
- start_date (TIMESTAMPTZ)
- end_date (TIMESTAMPTZ, Nullable)
- is_active (BOOLEAN, Default: TRUE)

#### **Table: group_expenses**

- id (UUID, Primary Key)
- creator_id (UUID, Foreign Key \-\> profiles.id)
- total_amount (NUMERIC(12, 2))
- description (TEXT)
- created_at (TIMESTAMPTZ)

#### **Table: group_split_items**

- id (UUID, Primary Key)
- group_expense_id (UUID, Foreign Key \-\> group_expenses.id ON DELETE CASCADE, Indexed)
- borrower_id (UUID, Foreign Key \-\> profiles.id, Indexed)
- assigned_amount (NUMERIC(12, 2))
- status (VARCHAR, Constraint: CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED')), Default: 'PENDING')
- resolved_at (TIMESTAMPTZ, Nullable)

### **3.2 Entity Relations**

- profiles has a One-to-Many relation with personal_transactions, budgets, and group_expenses (as a creator).
- group_expenses maps to a One-to-Many relation with group_split_items. The total sum of assigned_amount inside the child group_split_items records must exactly match the parent group_expenses.total_amount if the creator is included, or represent the total external split.
- group_split_items has a Optional One-to-One relation with personal_transactions, which is instantiated immediately upon the borrower_id shifting their status to 'ACCEPTED'.

## ---

**4\. Critical Business Logic & Workflows**

### **4.1 Wallet Mutation Constraints**

Changes to a user's wallet balance cannot happen dynamically on the frontend without server verification. The core data state follows these strict constraints:

- When a row is appended to personal_transactions with type \= 'INCOME', a database trigger automatically executes:  
  `UPDATE profiles SET wallet_balance = wallet_balance + NEW.amount WHERE id = NEW.user_id;`
- When a personal transaction row is added with type \= 'EXPENSE' (or when a group split item transitions to 'ACCEPTED'), the trigger updates the profile balance:  
  `UPDATE profiles SET wallet_balance = wallet_balance - NEW.amount WHERE id = NEW.user_id;`

### **4.2 Granular Custom Split & Acceptance Lifecycle Workflow**

The system executes a state-machine workflow to guarantee data integrity across split accounts:

1. **Initiation:** User A logs a total group bill of ₹1200 for food. In the app, User A selects User B and User C. User A custom allocates: User A \= ₹400, User B \= ₹500, User C \= ₹300.
2. **Persistence:** A single entry is added to group_expenses (total_amount \= 1200.00). Simultaneously, two entries are inserted into group_split_items:
   - Row 1: borrower_id \= User B, assigned_amount \= 500.00, status \= 'PENDING'
   - Row 2: borrower_id \= User C, assigned_amount \= 300.00, status \= 'PENDING'

User A's personal share (₹400) is automatically inserted into User A's personal_transactions table right away as an expense since they paid it.

3. **State Notification Loop:** User B opens the app. The home dashboard requests a real-time count of entries matching borrower_id \= User B AND status \= 'PENDING'. A warning banner shows up.
4. **Acceptance Transaction Phase:** When User B clicks "Accept":
   - An isolated backend transaction sets the status in group_split_items to 'ACCEPTED'.
   - An entry is added to personal_transactions for User B (type \= 'EXPENSE', amount \= 500.00, category \= 'Food', group_split_item_id \= this split row item).
   - The profile wallet trigger executes, decreasing User B's wallet_balance by ₹500.

### **4.3 Open-Ended Budget Tracking**

Because budget timelines are customizable and do not adhere to fixed calendar months, monitoring calculations are handled as a progressive range function:

- **Active Budget Query Window:** If a user requests metrics for an active budget where end_date IS NULL, the system evaluates all transactional expenses within the chronological bounds of \[start_date, NOW()\].
- Formally, the current consumed amount is defined by:  
  `SELECT COALESCE(SUM(amount), 0) FROM personal_transactions WHERE user_id = :current_user AND type = 'EXPENSE' AND transaction_date >= :budget_start_date;`
- **Closing Trigger:** When the user hits "End Budget Period", the backend updates end_date \= NOW() and toggles is_active \= FALSE. This locks the baseline summary data for that historical range, allowing the user to seamlessly initialize a clean new budget slate.

### **4.4 Secure OTP Authentication Flow**

Authentication utilizes Supabase Auth's built-in passwordless email mechanism:

1. The user inputs their email address on the Flutter UI client.
2. The application requests authentication via the SDK: supabase.auth.signInWithOtp(email: targetEmail).
3. The Supabase Go True backend sends a secure 6-digit cryptographic verification string to the user's email.
4. The user enters the verification token in the mobile app. The application submits the validation code to Supabase. Upon confirmation, a cryptographically signed JWT is returned to the client session, activating Row-Level Security permissions for subsequent database actions.

## ---

**5\. Data Export Architecture & Reporting Engine**

To scale export performance without introducing UI latency on the mobile device, data rendering tasks are handled off-thread by the FastAPI application server.

1. **Export Call Request:** The Flutter mobile app invokes a secure, authenticated POST request to the FastAPI application gateway endpoint (/api/v1/export), providing parameters specifying the preferred payload architecture (format: 'pdf' | 'excel'), alongside a date boundaries framework (start_bound_date and end_bound_date).
2. **Token Processing Validation:** The FastAPI server intercepts the authentication header, extracts the bearer JWT, and validates it against Supabase security keys to ensure the requesting identity matches the resource bounds requested.
3. **Query Aggregation Execution:** The application pulls the dataset containing all verified entries within the requested period parameters.
4. **Document Generation Assembly:**
   - **Excel Engine:** Utilizes openpyxl / pandas data matrices to write rows to an tracking spreadsheet, styling separate calculation columns tracking running wallet values, categorization labels, descriptions, and structural split indicators.
   - **PDF Engine:** Leverages a ReportLab layout architecture to generate a clean, official invoice-style ledger statement complete with summaries, categorization charts, and an audit footprint.
5. **Streaming Delivery Response:** The resulting file binary is streamed directly back over the network to the mobile client as an explicit application/octet-stream attachment payload. The Flutter system takes the stream and saves it locally via path_provider, opening the native sharing sheet (share_plus) for quick deployment to WhatsApp, Google Drive, or email.
