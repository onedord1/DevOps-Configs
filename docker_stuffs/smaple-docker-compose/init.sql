-- Create databases for both applications
CREATE DATABASE IF NOT EXISTS cyber_terminal;
CREATE DATABASE IF NOT EXISTS puzzle_paradise;

-- Use cyber_terminal database and create tables
USE cyber_terminal;

-- Users table for terminal authentication
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin', 'user') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Terminal sessions table
CREATE TABLE IF NOT EXISTS terminal_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    session_data TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- System logs table
CREATE TABLE IF NOT EXISTS system_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    command VARCHAR(255),
    output TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Create indexes for better performance
CREATE INDEX idx_sessions_user_id ON terminal_sessions(user_id);
CREATE INDEX idx_sessions_last_activity ON terminal_sessions(last_activity);
CREATE INDEX idx_logs_user_id ON system_logs(user_id);
CREATE INDEX idx_logs_timestamp ON system_logs(timestamp);

-- Insert sample admin user (password: admin123)
INSERT INTO users (username, email, password, role) VALUES 
('admin', 'admin@cybernexus.com', '$2a$10$8KxO7OvQfIWX0YnL8a7r7.7lL9.8kO9.7lL9.8kO9.7lL9.8kO9.', 'admin')
ON DUPLICATE KEY UPDATE username = username;

-- Switch to puzzle_paradise database and create tables
USE puzzle_paradise;

-- Users table for puzzle authentication
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Puzzles table
CREATE TABLE IF NOT EXISTS puzzles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'medium',
    data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Scores table
CREATE TABLE IF NOT EXISTS scores (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    puzzle_id INT,
    score INT NOT NULL,
    completion_time INT NOT NULL,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (puzzle_id) REFERENCES puzzles(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX idx_scores_user_id ON scores(user_id);
CREATE INDEX idx_scores_puzzle_id ON scores(puzzle_id);
CREATE INDEX idx_scores_completed_at ON scores(completed_at);
CREATE INDEX idx_puzzles_type ON puzzles(type);
CREATE INDEX idx_puzzles_difficulty ON puzzles(difficulty);

-- Insert sample puzzles
INSERT INTO puzzles (name, type, difficulty, data) VALUES 
('Sliding Puzzle', 'sliding', 'easy', '{"size": 3, "image": "puzzle1.jpg"}'),
('Memory Game', 'memory', 'medium', '{"pairs": 8, "theme": "numbers"}'),
('Pattern Puzzle', 'pattern', 'hard', '{"sequence_length": 5, "time_limit": 30}')
ON DUPLICATE KEY UPDATE name = name;

-- Insert sample user (password: puzzle123)
INSERT INTO users (username, email, password) VALUES 
('puzzleuser', 'user@puzzleparadise.com', '$2a$10$8KxO7OvQfIWX0YnL8a7r7.7lL9.8kO9.7lL9.8kO9.7lL9.8kO9.')
ON DUPLICATE KEY UPDATE username = username;

-- Create a user for the Node.js backend in the puzzle_paradise database for cross-platform functionality
INSERT INTO users (username, email, password) VALUES 
('cyberuser', 'cyber@puzzleparadise.com', '$2a$10$8KxO7OvQfIWX0YnL8a7r7.7lL9.8kO9.7lL9.8kO9.7lL9.8kO9.')
ON DUPLICATE KEY UPDATE username = username;

-- Create a user for the Python backend in the cyber_terminal database for cross-platform functionality
USE cyber_terminal;
INSERT INTO users (username, email, password, role) VALUES 
('puzzleadmin', 'puzzleadmin@cybernexus.com', '$2a$10$8KxO7OvQfIWX0YnL8a7r7.7lL9.8kO9.7lL9.8kO9.7lL9.8kO9.', 'user')
ON DUPLICATE KEY UPDATE username = username;
