-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 01, 2026 at 05:06 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `chatter_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `auth_tokens`
--

CREATE TABLE `auth_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `token` varchar(500) NOT NULL,
  `device_name` varchar(100) DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `auth_tokens`
--

INSERT INTO `auth_tokens` (`id`, `user_id`, `token`, `device_name`, `expires_at`, `created_at`) VALUES
(1, 6, '73863f77202ef9febbd6043feea58a4f7a6254bb7a2ca6a813f9cb0f9f881ea71bd434e1f640990e', NULL, '2026-04-08 11:13:38', '2026-04-01 18:13:38'),
(2, 6, 'd5fe85b2fb26845a123b2e6c043199d9d0db02fd82f9b32925d5bf8bd856fd1cd680564b993befe2', NULL, '2026-04-08 11:14:46', '2026-04-01 18:14:46'),
(3, 6, 'ff4d9ffd69a71ac088e08aa2a32813331116e977e77b29a75427d3301329c365b3ed24a3c2c36b9d', NULL, '2026-04-08 11:25:05', '2026-04-01 18:25:05'),
(7, 2, 'dd0abd6736923e133551243b5fd92bbdaea026f318cb09a2f1d80e02b9fb46e968cac84c03b2703a', NULL, '2026-04-08 11:46:40', '2026-04-01 18:46:40'),
(8, 2, '0c7471e1f377b4265a7184a93a4dcadf60735867478b283f0207d32baf50696ef206ba10fcc32a8c', NULL, '2026-04-08 11:51:49', '2026-04-01 18:51:49'),
(9, 6, '7653c89fbe0d7cc6081d7040a2ef40af051dc1394a4766fe1b7ef863a74db485af7268a51a78267c', NULL, '2026-04-08 11:54:50', '2026-04-01 18:54:50'),
(10, 2, 'c42af992aec48782209745fbd5db2e391309db318d58c2289b004385a3d95b18d4a812b711237ffe', NULL, '2026-04-08 11:56:27', '2026-04-01 18:56:27'),
(11, 2, '12f743780d1f9862f48df145f8cd72e242f838bfcef00f989f3ba4506a5d1c1a9d0727c4dc4b0f26', NULL, '2026-04-08 12:43:03', '2026-04-01 19:43:03'),
(12, 6, 'a9475dfec6c1e0eb6f2448da1ba11d0d925b2843ab60c2260c086f1ec0bf74bc54ae449b0d34629c', NULL, '2026-04-08 12:43:07', '2026-04-01 19:43:07'),
(13, 2, '6b1d348e198571cfa1cc2fa538b1e02b9ff5552d8627a020e43bbab5ee3481b92a88b0284631e821', NULL, '2026-04-08 15:01:59', '2026-04-01 22:01:59');

-- --------------------------------------------------------

--
-- Table structure for table `contacts`
--

CREATE TABLE `contacts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `contact_id` bigint(20) UNSIGNED NOT NULL,
  `status` enum('pending','accepted','blocked') DEFAULT 'pending',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `contacts`
--

INSERT INTO `contacts` (`id`, `user_id`, `contact_id`, `status`, `created_at`, `updated_at`) VALUES
(1, 6, 2, 'accepted', '2026-04-01 15:02:16', '2026-04-01 15:02:16'),
(2, 2, 6, 'accepted', '2026-04-01 15:02:16', '2026-04-01 15:02:16');

-- --------------------------------------------------------

--
-- Table structure for table `conversations`
--

CREATE TABLE `conversations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `type` enum('direct','group') DEFAULT 'direct',
  `name` varchar(150) DEFAULT NULL,
  `avatar_url` varchar(500) DEFAULT NULL,
  `created_by` bigint(20) UNSIGNED NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `conversations`
--

INSERT INTO `conversations` (`id`, `type`, `name`, `avatar_url`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'direct', NULL, NULL, 6, '2026-04-01 15:02:19', '2026-04-01 15:03:12');

-- --------------------------------------------------------

--
-- Table structure for table `conversation_participants`
--

CREATE TABLE `conversation_participants` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `conversation_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `role` enum('member','admin') DEFAULT 'member',
  `joined_at` datetime DEFAULT current_timestamp(),
  `last_read_at` datetime DEFAULT NULL,
  `is_muted` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `conversation_participants`
--

INSERT INTO `conversation_participants` (`id`, `conversation_id`, `user_id`, `role`, `joined_at`, `last_read_at`, `is_muted`) VALUES
(1, 1, 6, 'member', '2026-04-01 22:02:19', '2026-04-01 15:02:20', 0),
(2, 1, 2, 'member', '2026-04-01 22:02:19', '2026-04-01 15:03:45', 0);

-- --------------------------------------------------------

--
-- Table structure for table `messages`
--

CREATE TABLE `messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `conversation_id` bigint(20) UNSIGNED NOT NULL,
  `sender_id` bigint(20) UNSIGNED NOT NULL,
  `reply_to_id` bigint(20) UNSIGNED DEFAULT NULL,
  `type` enum('text','image','audio','file','emoji') DEFAULT 'text',
  `content` text NOT NULL,
  `media_url` varchar(500) DEFAULT NULL,
  `is_deleted` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `messages`
--

INSERT INTO `messages` (`id`, `conversation_id`, `sender_id`, `reply_to_id`, `type`, `content`, `media_url`, `is_deleted`, `created_at`, `updated_at`) VALUES
(1, 1, 6, NULL, 'text', 'hi\nhow are you banana', NULL, 0, '2026-04-01 15:02:32', '2026-04-01 15:02:32'),
(2, 1, 2, NULL, 'text', 'bazinga', NULL, 0, '2026-04-01 15:03:12', '2026-04-01 15:03:12');

-- --------------------------------------------------------

--
-- Table structure for table `message_reads`
--

CREATE TABLE `message_reads` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `message_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `read_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `message_reads`
--

INSERT INTO `message_reads` (`id`, `message_id`, `user_id`, `read_at`) VALUES
(1, 1, 6, '2026-04-01 22:02:32'),
(2, 2, 2, '2026-04-01 22:03:12');

-- --------------------------------------------------------

--
-- Table structure for table `stories`
--

CREATE TABLE `stories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `type` enum('text','image','video') DEFAULT 'text',
  `content` text DEFAULT NULL,
  `media_url` varchar(500) DEFAULT NULL,
  `bg_color` varchar(20) DEFAULT '#6C63FF',
  `expires_at` datetime NOT NULL,
  `created_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `story_views`
--

CREATE TABLE `story_views` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `story_id` bigint(20) UNSIGNED NOT NULL,
  `viewer_id` bigint(20) UNSIGNED NOT NULL,
  `viewed_at` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `avatar_url` varchar(500) DEFAULT NULL,
  `status` enum('online','away','offline') DEFAULT 'offline',
  `status_message` varchar(150) DEFAULT NULL,
  `last_seen_at` datetime DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `username`, `email`, `password_hash`, `avatar_url`, `status`, `status_message`, `last_seen_at`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Alex Johnson', 'alexj', 'alex@chatter.app', '$2y$12$RCsDDOiUjPrwVrAyx2yS9eCep2s.GMV1JW5UvRWZWAKbVO5kGbCga', 'https://i.pravatar.cc/150?img=12', 'online', NULL, NULL, 1, '2026-04-01 16:13:47', '2026-04-01 18:35:27'),
(2, 'Ariana Wells', 'ariana', 'ariana@chatter.app', '$2y$12$RCsDDOiUjPrwVrAyx2yS9eCep2s.GMV1JW5UvRWZWAKbVO5kGbCga', 'https://i.pravatar.cc/150?img=47', 'offline', NULL, '2026-04-01 15:03:53', 1, '2026-04-01 16:13:47', '2026-04-01 15:03:53'),
(3, 'Marcus Chen', 'marcus', 'marcus@chatter.app', '$2y$12$RCsDDOiUjPrwVrAyx2yS9eCep2s.GMV1JW5UvRWZWAKbVO5kGbCga', 'https://i.pravatar.cc/150?img=33', 'away', NULL, NULL, 1, '2026-04-01 16:13:47', '2026-04-01 18:35:30'),
(4, 'Sofia Reyes', 'sofia', 'sofia@chatter.app', '$2y$12$RCsDDOiUjPrwVrAyx2yS9eCep2s.GMV1JW5UvRWZWAKbVO5kGbCga', 'https://i.pravatar.cc/150?img=56', 'online', NULL, NULL, 1, '2026-04-01 16:13:47', '2026-04-01 18:35:32'),
(5, 'Priya Nair', 'priya', 'priya@chatter.app', '$2y$12$RCsDDOiUjPrwVrAyx2yS9eCep2s.GMV1JW5UvRWZWAKbVO5kGbCga', 'https://i.pravatar.cc/150?img=62', 'online', NULL, NULL, 1, '2026-04-01 16:13:47', '2026-04-01 18:35:34'),
(6, 'Test User', 'testuser', 'test@gmail.com', '$2y$12$RCsDDOiUjPrwVrAyx2yS9eCep2s.GMV1JW5UvRWZWAKbVO5kGbCga', NULL, 'offline', NULL, '2026-04-01 15:02:37', 1, '2026-04-01 11:13:38', '2026-04-01 15:02:37');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `auth_tokens`
--
ALTER TABLE `auth_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `idx_token` (`token`(100)),
  ADD KEY `idx_user_id` (`user_id`);

--
-- Indexes for table `contacts`
--
ALTER TABLE `contacts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_contact` (`user_id`,`contact_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_contact_id` (`contact_id`),
  ADD KEY `idx_status` (`status`);

--
-- Indexes for table `conversations`
--
ALTER TABLE `conversations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `idx_type` (`type`),
  ADD KEY `idx_updated_at` (`updated_at`);

--
-- Indexes for table `conversation_participants`
--
ALTER TABLE `conversation_participants`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_conv_user` (`conversation_id`,`user_id`),
  ADD KEY `idx_user_id` (`user_id`);

--
-- Indexes for table `messages`
--
ALTER TABLE `messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `reply_to_id` (`reply_to_id`),
  ADD KEY `idx_conversation_id` (`conversation_id`),
  ADD KEY `idx_sender_id` (`sender_id`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `message_reads`
--
ALTER TABLE `message_reads`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_msg_user` (`message_id`,`user_id`),
  ADD KEY `idx_message_id` (`message_id`),
  ADD KEY `idx_user_id` (`user_id`);

--
-- Indexes for table `stories`
--
ALTER TABLE `stories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_expires_at` (`expires_at`);

--
-- Indexes for table `story_views`
--
ALTER TABLE `story_views`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_story_viewer` (`story_id`,`viewer_id`),
  ADD KEY `viewer_id` (`viewer_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_username` (`username`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_status` (`status`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `auth_tokens`
--
ALTER TABLE `auth_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

--
-- AUTO_INCREMENT for table `contacts`
--
ALTER TABLE `contacts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `conversations`
--
ALTER TABLE `conversations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `conversation_participants`
--
ALTER TABLE `conversation_participants`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `messages`
--
ALTER TABLE `messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `message_reads`
--
ALTER TABLE `message_reads`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `stories`
--
ALTER TABLE `stories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `story_views`
--
ALTER TABLE `story_views`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `auth_tokens`
--
ALTER TABLE `auth_tokens`
  ADD CONSTRAINT `auth_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `contacts`
--
ALTER TABLE `contacts`
  ADD CONSTRAINT `contacts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `contacts_ibfk_2` FOREIGN KEY (`contact_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `conversations`
--
ALTER TABLE `conversations`
  ADD CONSTRAINT `conversations_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`);

--
-- Constraints for table `conversation_participants`
--
ALTER TABLE `conversation_participants`
  ADD CONSTRAINT `conversation_participants_ibfk_1` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `conversation_participants_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `messages_ibfk_1` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `messages_ibfk_2` FOREIGN KEY (`sender_id`) REFERENCES `users` (`id`),
  ADD CONSTRAINT `messages_ibfk_3` FOREIGN KEY (`reply_to_id`) REFERENCES `messages` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `message_reads`
--
ALTER TABLE `message_reads`
  ADD CONSTRAINT `message_reads_ibfk_1` FOREIGN KEY (`message_id`) REFERENCES `messages` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `message_reads_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `stories`
--
ALTER TABLE `stories`
  ADD CONSTRAINT `stories_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `story_views`
--
ALTER TABLE `story_views`
  ADD CONSTRAINT `story_views_ibfk_1` FOREIGN KEY (`story_id`) REFERENCES `stories` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `story_views_ibfk_2` FOREIGN KEY (`viewer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
