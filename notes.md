```go

type Store interface {
	Querier
    type Querier interface {
        AddAccountBalance(ctx context.Context, arg AddAccountBalanceParams) (Account, error)
        CreateAccount(ctx context.Context, arg CreateAccountParams) (Account, error)
        CreateEntry(ctx context.Context, arg CreateEntryParams) (Entry, error)
        CreateSession(ctx context.Context, arg CreateSessionParams) (Session, error)
        CreateTransfer(ctx context.Context, arg CreateTransferParams) (Transfer, error)
        CreateUser(ctx context.Context, arg CreateUserParams) (User, error)
        DeleteAccount(ctx context.Context, id int64) error
        GetAccount(ctx context.Context, id int64) (Account, error)
        GetAccountForUpdate(ctx context.Context, id int64) (Account, error)
        GetEntry(ctx context.Context, id int64) (Entry, error)
        GetSession(ctx context.Context, id uuid.UUID) (Session, error)
        GetTransfer(ctx context.Context, id int64) (Transfer, error)
        GetUser(ctx context.Context, username string) (User, error)
        ListAccounts(ctx context.Context, arg ListAccountsParams) ([]Account, error)
        ListEntries(ctx context.Context, arg ListEntriesParams) ([]Entry, error)
        ListTransfers(ctx context.Context, arg ListTransfersParams) ([]Transfer, error)
        UpdateAccount(ctx context.Context, arg UpdateAccountParams) (Account, error)
    }
	TransferTx(ctx context.Context, arg TransferTxParams) (TransferTxResult, error)

}
func NewStore(db *sql.DB) Store { return &SQLStore{db: db, Queries: New(db)} }


type SQLStore struct {
	*Queries
	db *sql.DB
    type Queries struct {
        db DBTX
            type DBTX interface {
                ExecContext(context.Context, string, ...interface{}) (sql.Result, error)
                PrepareContext(context.Context, string) (*sql.Stmt, error)
                QueryContext(context.Context, string, ...interface{}) (*sql.Rows, error)
                QueryRowContext(context.Context, string, ...interface{}) *sql.Row
            }
        WithTx(tx *sql.Tx) *Queries { return &Queries{ db: tx, } }
        func (q *Queries) AddAccountBalance(ctx context.Context, arg AddAccountBalanceParams) (Account, error)
        func (q *Queries) CreateAccount(ctx context.Context, arg CreateAccountParams) (Account, error)
        func (q *Queries) DeleteAccount(ctx context.Context, id int64) error {}
        func (q *Queries) GetAccount(ctx context.Context, id int64) (Account, error)
        func (q *Queries) GetAccountForUpdate(ctx context.Context, id int64) (Account, error)
        func (q *Queries) ListAccounts(ctx context.Context, arg ListAccountsParams) ([]Account, error)
        func (q *Queries) UpdateAccount(ctx context.Context, arg UpdateAccountParams) (Account, error)
        func (q *Queries) CreateEntry(ctx context.Context, arg CreateEntryParams) (Entry, error)
        func (q *Queries) GetEntry(ctx context.Context, id int64) (Entry, error)
        func (q *Queries) ListEntries(ctx context.Context, arg ListEntriesParams) ([]Entry, error)
        func (q *Queries) CreateSession(ctx context.Context, arg CreateSessionParams) (Session, error)
        func (q *Queries) GetSession(ctx context.Context, id uuid.UUID) (Session, error)
        func (q *Queries) CreateTransfer(ctx context.Context, arg CreateTransferParams) (Transfer, error)
        func (q *Queries) GetTransfer(ctx context.Context, id int64) (Transfer, error)
        func (q *Queries) ListTransfers(ctx context.Context, arg ListTransfersParams) ([]Transfer, error)
        func (q *Queries) CreateUser(ctx context.Context, arg CreateUserParams) (User, error)
        func (q *Queries) GetUser(ctx context.Context, username string) (User, error)
    }
    func (s *SQLStore) execTx(ctx context.Context, fn func(queries *Queries) error) error {}
    func (s *SQLStore) TransferTx(ctx context.Context, arg TransferTxParams) (TransferTxResult, error) {}
}
func New(db DBTX) *Queries { return &Queries{db: db} }


// TransferTxParams contains the input parameters of the transfer transaction.
type TransferTxParams struct {
	FromAccountID int64 `json:"from_account_id"`
	ToAccountID   int64 `json:"to_account_id"`
	Amount        int64 `json:"amount"`
}

// TransferTxResult is the result of the transfer transaction.
type TransferTxResult struct {
	Transfer    Transfer `json:"transfer"`
	FromAccount Account  `json:"from_account"`
	ToAccount   Account  `json:"to_account"`
	FromEntry   Entry    `json:"from_entry"`
	ToEntry     Entry    `json:"to_entry"`
}

type Server struct {
	config     util.Config
	store      db.Store
	tokenMaker token.Maker
	router     *gin.Engine
    func (server *Server) setupRouter()
    func (server *Server) Start(address string) error {}
    func (server *Server) createAccount(ctx *gin.Context)
    func (server *Server) getAccount(ctx *gin.Context)
    func (server *Server) listAccount(ctx *gin.Context)
    func (server *Server) deleteAccount(ctx *gin.Context)
    func (server *Server) renewAccessToken(ctx *gin.Context)
    func (server *Server) createTransfer(ctx *gin.Context)
    func (server *Server) validAccount(ctx *gin.Context, accountID int64, currency string) (db.Account, bool)
    func (server *Server) createUser(ctx *gin.Context)
    func (server *Server) loginUSer(ctx *gin.Context)
}
func NewServer(config util.Config, store db.Store) (*Server, error)

func main() {
	config, err := util.LoadConfig(".")
	conn, err := sql.Open(config.DBDriver, config.DBSource)
	store := db.NewStore(conn)
	server, err := api.NewServer(config, store)
	err = server.Start(config.ServerAddress)
}






```



