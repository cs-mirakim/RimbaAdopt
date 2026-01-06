-- USERS
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role ENUM('admin','adopter','shelter') NOT NULL,
    profile_photo_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ADMIN
CREATE TABLE admin (
    admin_id INT PRIMARY KEY,
    position VARCHAR(100),
    FOREIGN KEY (admin_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- ADOPTER
CREATE TABLE adopter (
    adopter_id INT PRIMARY KEY,
    address VARCHAR(255),
    occupation VARCHAR(100),
    household_type VARCHAR(100),
    has_other_pets BOOLEAN DEFAULT FALSE,
    notes TEXT,
    FOREIGN KEY (adopter_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

-- SHELTER
CREATE TABLE shelter (
    shelter_id INT PRIMARY KEY,
    shelter_name VARCHAR(150) NOT NULL,
    shelter_address VARCHAR(255) NOT NULL,
    shelter_description TEXT,
    website VARCHAR(255),
    operating_hours VARCHAR(255),
    -- APPROVAL SYSTEM
    approval_status ENUM('pending','approved','rejected') DEFAULT 'pending',
    reviewed_by INT NULL,               -- admin yang approve atau reject
    reviewed_at DATETIME NULL,          -- timestamp bila admin proses
    approval_message TEXT NULL,         -- mesej admin jika approved
    rejection_reason TEXT NULL,         -- reason jika rejected
    notification_sent TINYINT(1) DEFAULT 0, -- 0=belum hantar email, 1=pernah hantar
    notification_sent_at DATETIME NULL, -- bila email dihantar
    FOREIGN KEY (shelter_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (reviewed_by) REFERENCES admin(admin_id)
) ENGINE=InnoDB;

-- PETS
CREATE TABLE pets (
    pet_id INT AUTO_INCREMENT PRIMARY KEY,
    shelter_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    species VARCHAR(50) NOT NULL,
    breed VARCHAR(100),
    age INT,
    gender ENUM('male','female'),
    size ENUM('small','medium','large'),
    color VARCHAR(50),
    description TEXT,
    health_status VARCHAR(255),
    photo_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shelter_id) REFERENCES shelter(shelter_id)
) ENGINE=InnoDB;

-- ADOPTION REQUEST
CREATE TABLE adoption_request (
    request_id INT AUTO_INCREMENT PRIMARY KEY,
    adopter_id INT NOT NULL,
    pet_id INT NOT NULL,
    request_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending','approved','rejected','cancelled') DEFAULT 'pending',
    adopter_message TEXT, -- The Adopter's initial message/reason for adoption
    shelter_response TEXT,
    cancellation_reason TEXT, -- NEW: Reason provided by Adopter for cancelling the request
    FOREIGN KEY (adopter_id) REFERENCES adopter(adopter_id),
    FOREIGN KEY (pet_id) REFERENCES pets(pet_id)
) ENGINE=InnoDB;

-- ADOPTION RECORD
CREATE TABLE adoption_record (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    request_id INT NOT NULL,
    adopter_id INT NOT NULL,
    pet_id INT NOT NULL,
    adoption_date DATE NOT NULL,
    remarks TEXT,
    FOREIGN KEY (request_id) REFERENCES adoption_request(request_id),
    FOREIGN KEY (adopter_id) REFERENCES adopter(adopter_id),
    FOREIGN KEY (pet_id) REFERENCES pets(pet_id)
) ENGINE=InnoDB;

-- LOST REPORT
CREATE TABLE lost_report (
    lost_id INT AUTO_INCREMENT PRIMARY KEY,
    adopter_id INT NOT NULL,
    pet_name VARCHAR(100) NOT NULL,
    species VARCHAR(50) NOT NULL,
    last_seen_location VARCHAR(255),
    last_seen_date DATE,
    description TEXT,
    photo_path VARCHAR(255),
    status ENUM('lost','found') DEFAULT 'lost',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (adopter_id) REFERENCES adopter(adopter_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- FEEDBACK
CREATE TABLE feedback (
    feedback_id INT AUTO_INCREMENT PRIMARY KEY,
    adopter_id INT NOT NULL,
    shelter_id INT NOT NULL,
    rating INT,
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (adopter_id) REFERENCES adopter(adopter_id),
    FOREIGN KEY (shelter_id) REFERENCES shelter(shelter_id)
) ENGINE=InnoDB;

-- AWARENESS BANNER / POSTER
CREATE TABLE awareness_banner (
    banner_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    image_path VARCHAR(255) NOT NULL,     -- lokasi fail gambar
    status ENUM('visible','hidden') DEFAULT 'visible',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INT,                       -- admin yang upload
    FOREIGN KEY (created_by) REFERENCES admin(admin_id)
        ON DELETE SET NULL
);
