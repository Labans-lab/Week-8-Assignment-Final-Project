-- Clinic Booking System - Complete MySQL Schema
-- Created: 2025-09-24
-- Contains: CREATE DATABASE, CREATE TABLEs, constraints, and relationships

CREATE DATABASE IF NOT EXISTS `clinic_booking` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `clinic_booking`;

-- -----------------------------------------------------
-- Table: roles (lookup)
-- -----------------------------------------------------
CREATE TABLE `roles` (
  `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL UNIQUE,
  `description` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: users (system users: admin, receptionist, etc.)
-- -----------------------------------------------------
CREATE TABLE `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(100) NOT NULL UNIQUE,
  `email` VARCHAR(255) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `role_id` TINYINT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_login` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: patients
-- -----------------------------------------------------
CREATE TABLE `patients` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) NOT NULL,
  `dob` DATE NOT NULL,
  `gender` ENUM('Male','Female','Other') DEFAULT 'Other',
  `phone` VARCHAR(20) DEFAULT NULL,
  `email` VARCHAR(255) DEFAULT NULL,
  `address` VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_patient_email_phone` (`email`,`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: doctors
-- -----------------------------------------------------
CREATE TABLE `doctors` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `first_name` VARCHAR(100) NOT NULL,
  `last_name` VARCHAR(100) NOT NULL,
  `phone` VARCHAR(20) DEFAULT NULL,
  `email` VARCHAR(255) DEFAULT NULL,
  `license_number` VARCHAR(100) NOT NULL UNIQUE,
  `hire_date` DATE DEFAULT NULL,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: specialties (lookup) and doctor_specialties (M:N)
-- -----------------------------------------------------
CREATE TABLE `specialties` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL UNIQUE,
  `description` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `doctor_specialties` (
  `doctor_id` INT UNSIGNED NOT NULL,
  `specialty_id` SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (`doctor_id`,`specialty_id`),
  CONSTRAINT `fk_ds_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctors`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ds_specialty` FOREIGN KEY (`specialty_id`) REFERENCES `specialties`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: rooms
-- -----------------------------------------------------
CREATE TABLE `rooms` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `room_number` VARCHAR(20) NOT NULL UNIQUE,
  `type` ENUM('Consultation','MinorProcedure','Exam','Recovery') DEFAULT 'Consultation',
  `notes` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: appointment_status (lookup)
-- -----------------------------------------------------
CREATE TABLE `appointment_status` (
  `id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL UNIQUE,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- seed common statuses (optional)
INSERT INTO `appointment_status` (`name`) VALUES ('Scheduled'), ('Checked-in'), ('Completed'), ('Cancelled'), ('No-Show')
  ON DUPLICATE KEY UPDATE `name` = `name`;

-- -----------------------------------------------------
-- Table: appointments
-- -----------------------------------------------------
CREATE TABLE `appointments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `doctor_id` INT UNSIGNED NOT NULL,
  `room_id` SMALLINT UNSIGNED NULL,
  `scheduled_start` DATETIME NOT NULL,
  `scheduled_end` DATETIME NOT NULL,
  `status_id` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `reason` VARCHAR(500) DEFAULT NULL,
  `created_by` INT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_appt_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_appt_doctor` FOREIGN KEY (`doctor_id`) REFERENCES `doctors`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_appt_room` FOREIGN KEY (`room_id`) REFERENCES `rooms`(`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_appt_status` FOREIGN KEY (`status_id`) REFERENCES `appointment_status`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_appt_created_by` FOREIGN KEY (`created_by`) REFERENCES `users`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX `idx_appt_patient` (`patient_id`),
  INDEX `idx_appt_doctor` (`doctor_id`),
  INDEX `idx_appt_sched` (`scheduled_start`,`scheduled_end`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Add a constraint to prevent appointments where scheduled_end <= scheduled_start
ALTER TABLE `appointments` ADD CONSTRAINT `chk_appt_times` CHECK (`scheduled_end` > `scheduled_start`);

-- -----------------------------------------------------
-- Table: services (procedures / consultation types)
-- -----------------------------------------------------
CREATE TABLE `services` (
  `id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(30) NOT NULL UNIQUE,
  `name` VARCHAR(150) NOT NULL,
  `description` VARCHAR(500) DEFAULT NULL,
  `duration_minutes` SMALLINT UNSIGNED DEFAULT 30,
  `price` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Many-to-many: appointments <-> services (an appointment can include several billable services)
CREATE TABLE `appointment_services` (
  `appointment_id` BIGINT UNSIGNED NOT NULL,
  `service_id` SMALLINT UNSIGNED NOT NULL,
  `qty` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  PRIMARY KEY (`appointment_id`,`service_id`),
  CONSTRAINT `fk_as_appointment` FOREIGN KEY (`appointment_id`) REFERENCES `appointments`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_as_service` FOREIGN KEY (`service_id`) REFERENCES `services`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: prescriptions
-- -----------------------------------------------------
CREATE TABLE `medications` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(200) NOT NULL,
  `manufacturer` VARCHAR(200) DEFAULT NULL,
  `dosage_form` VARCHAR(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `prescriptions` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `appointment_id` BIGINT UNSIGNED NOT NULL,
  `prescribed_by` INT UNSIGNED NOT NULL,
  `issued_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `notes` VARCHAR(1000) DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_presc_appointment` FOREIGN KEY (`appointment_id`) REFERENCES `appointments`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_presc_by` FOREIGN KEY (`prescribed_by`) REFERENCES `doctors`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `prescription_items` (
  `prescription_id` BIGINT UNSIGNED NOT NULL,
  `medication_id` INT UNSIGNED NOT NULL,
  `dosage` VARCHAR(100) DEFAULT NULL,
  `frequency` VARCHAR(100) DEFAULT NULL,
  `duration_days` SMALLINT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`prescription_id`,`medication_id`),
  CONSTRAINT `fk_pi_prescription` FOREIGN KEY (`prescription_id`) REFERENCES `prescriptions`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_pi_medication` FOREIGN KEY (`medication_id`) REFERENCES `medications`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: invoices & payments
-- -----------------------------------------------------
CREATE TABLE `invoices` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `appointment_id` BIGINT UNSIGNED NOT NULL UNIQUE,
  `issued_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `total_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `paid_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `status` ENUM('Unpaid','Partially Paid','Paid','Refunded') NOT NULL DEFAULT 'Unpaid',
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_invoice_appointment` FOREIGN KEY (`appointment_id`) REFERENCES `appointments`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `payments` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `invoice_id` BIGINT UNSIGNED NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `method` ENUM('Cash','Card','MobileMoney','Insurance') NOT NULL DEFAULT 'Cash',
  `paid_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reference` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_payment_invoice` FOREIGN KEY (`invoice_id`) REFERENCES `invoices`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: medical_records (one-to-one with patient using unique patient_id)
-- -----------------------------------------------------
CREATE TABLE `medical_records` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `patient_id` INT UNSIGNED NOT NULL,
  `record_number` VARCHAR(100) NOT NULL UNIQUE,
  `height_cm` DECIMAL(5,2) DEFAULT NULL,
  `weight_kg` DECIMAL(6,2) DEFAULT NULL,
  `blood_group` VARCHAR(5) DEFAULT NULL,
  `allergies` VARCHAR(1000) DEFAULT NULL,
  `chronic_conditions` VARCHAR(1000) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_mr_patient` FOREIGN KEY (`patient_id`) REFERENCES `patients`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY `uniq_medrec_patient` (`patient_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Table: audit_logs (lightweight audit trail)
-- -----------------------------------------------------
CREATE TABLE `audit_logs` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id` INT UNSIGNED NULL,
  `action` VARCHAR(255) NOT NULL,
  `table_name` VARCHAR(100) DEFAULT NULL,
  `row_id` VARCHAR(100) DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_audit_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------
-- Helpful indexes
-- -----------------------------------------------------
ALTER TABLE `patients` ADD INDEX `idx_pat_name` (`last_name`, `first_name`);
ALTER TABLE `doctors` ADD INDEX `idx_doc_name` (`last_name`, `first_name`);
ALTER TABLE `appointments` ADD INDEX `idx_appt_status_start` (`status_id`,`scheduled_start`);

-- -----------------------------------------------------
-- Example: create some roles and a sample admin user (useful during initial deploy)
-- NOTE: Replace password_hash with a real salted hash in production
-- -----------------------------------------------------
INSERT INTO `roles` (`name`, `description`) VALUES ('Admin','System administrator'), ('Receptionist','Front desk'), ('Doctor','Medical staff')
  ON DUPLICATE KEY UPDATE `name` = `name`;

INSERT INTO `users` (`username`,`email`,`password_hash`,`role_id`) 
  SELECT 'admin','admin@clinic.local','REPLACE_WITH_SECURE_HASH', (SELECT `id` FROM `roles` WHERE `name`='Admin')
  FROM DUAL
  WHERE NOT EXISTS (SELECT 1 FROM `users` WHERE `username`='admin');

-- End of schema

-- Notes:
-- 1) This schema uses InnoDB and includes primary/foreign keys and many-to-many tables.
-- 2) Enforce additional business rules at the application layer (e.g., double-booking prevention, permissions).
-- 3) For MySQL versions prior to 8.0, some CHECK constraints may be parsed but ignored. Validate with your server version.
