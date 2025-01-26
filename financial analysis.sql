-- Step 1: Create database
CREATE DATABASE FinancialAnalysisDB;
USE FinancialAnalysisDB;

-- Step 2: Create Customers table
CREATE TABLE Customers (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Phone VARCHAR(15),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Step 3: Create Accounts table
CREATE TABLE Accounts (
    AccountID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT,
    AccountType ENUM('Savings', 'Checking', 'Credit', 'Loan'),
    Balance DECIMAL(15,2) DEFAULT 0.00,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE CASCADE
);

-- Step 4: Create Transactions table
CREATE TABLE Transactions (
    TransactionID INT AUTO_INCREMENT PRIMARY KEY,
    AccountID INT,
    TransactionType ENUM('Deposit', 'Withdrawal', 'Transfer', 'Payment'),
    Amount DECIMAL(15,2) NOT NULL,
    TransactionDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Description TEXT,
    FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID) ON DELETE CASCADE
);

-- Step 5: Create Expenses table
CREATE TABLE Expenses (
    ExpenseID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT,
    Category VARCHAR(50),
    Amount DECIMAL(15,2),
    ExpenseDate DATE,
    Description TEXT,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE CASCADE
);

-- Step 6: Insert sample data
INSERT INTO Customers (FirstName, LastName, Email, Phone) 
VALUES 
('John', 'Doe', 'john.doe@example.com', '1234567890'),
('Jane', 'Smith', 'jane.smith@example.com', '0987654321');

INSERT INTO Accounts (CustomerID, AccountType, Balance) 
VALUES 
(1, 'Savings', 5000.00),
(2, 'Checking', 2500.00);

INSERT INTO Transactions (AccountID, TransactionType, Amount, Description) 
VALUES 
(1, 'Deposit', 2000.00, 'Salary Payment'),
(2, 'Withdrawal', 500.00, 'Grocery Shopping'),
(1, 'Transfer', 1000.00, 'Rent Payment');

INSERT INTO Expenses (CustomerID, Category, Amount, ExpenseDate, Description) 
VALUES 
(1, 'Food', 200.00, '2024-01-15', 'Lunch at a restaurant'),
(2, 'Travel', 150.00, '2024-01-20', 'Cab fare to airport');

-- Step 7: Create a view to analyze total balance per customer
CREATE VIEW CustomerBalance AS
SELECT 
    c.CustomerID, 
    CONCAT(c.FirstName, ' ', c.LastName) AS FullName, 
    SUM(a.Balance) AS TotalBalance
FROM Customers c
JOIN Accounts a ON c.CustomerID = a.CustomerID
GROUP BY c.CustomerID;

-- Step 8: Create a stored procedure to calculate total transactions per account
DELIMITER //
CREATE PROCEDURE GetTotalTransactions(IN accID INT)
BEGIN
    SELECT 
        AccountID, 
        COUNT(*) AS TotalTransactions, 
        SUM(Amount) AS TotalAmount 
    FROM Transactions 
    WHERE AccountID = accID 
    GROUP BY AccountID;
END //
DELIMITER ;

-- Step 9: Create a trigger to prevent withdrawals exceeding balance
DELIMITER //
CREATE TRIGGER BeforeWithdrawal
BEFORE INSERT ON Transactions
FOR EACH ROW
BEGIN
    DECLARE acc_balance DECIMAL(15,2);
    SELECT Balance INTO acc_balance FROM Accounts WHERE AccountID = NEW.AccountID;
    IF NEW.TransactionType = 'Withdrawal' AND NEW.Amount > acc_balance THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Insufficient funds for withdrawal.';
    END IF;
END //
DELIMITER ;

-- Step 10: Useful queries for financial analysis

-- 1. Get all transactions for a specific customer
SELECT t.TransactionID, c.FirstName, c.LastName, t.TransactionType, t.Amount, t.TransactionDate
FROM Transactions t
JOIN Accounts a ON t.AccountID = a.AccountID
JOIN Customers c ON a.CustomerID = c.CustomerID
WHERE c.CustomerID = 1;

-- 2. Get total revenue from deposits
SELECT 
    SUM(Amount) AS TotalRevenue 
FROM Transactions 
WHERE TransactionType = 'Deposit';

-- 3. Get top 5 highest spending customers
SELECT 
    c.CustomerID, 
    CONCAT(c.FirstName, ' ', c.LastName) AS FullName, 
    SUM(e.Amount) AS TotalExpenses
FROM Expenses e
JOIN Customers c ON e.CustomerID = c.CustomerID
GROUP BY c.CustomerID
ORDER BY TotalExpenses DESC
LIMIT 5;

-- 4. Calculate monthly expense summary
SELECT 
    MONTH(ExpenseDate) AS Month, 
    SUM(Amount) AS MonthlyExpense
FROM Expenses
GROUP BY Month
ORDER BY Month;

-- 5. List accounts with low balance (below $1000)
SELECT 
    a.AccountID, 
    c.FirstName, 
    c.LastName, 
    a.Balance 
FROM Accounts a
JOIN Customers c ON a.CustomerID = c.CustomerID
WHERE a.Balance < 1000;

-- Step 11: Indexing for better performance
CREATE INDEX idx_customer_email ON Customers(Email);
CREATE INDEX idx_transaction_account ON Transactions(AccountID);
