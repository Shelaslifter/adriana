/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bitacora_tomas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `adulto_mayor_id` int(11) NOT NULL,
  `medicamento_id` int(11) NOT NULL,
  `fecha_hora` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `adulto_mayor_id` (`adulto_mayor_id`),
  KEY `medicamento_id` (`medicamento_id`),
  CONSTRAINT `bitacora_tomas_ibfk_1` FOREIGN KEY (`adulto_mayor_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE,
  CONSTRAINT `bitacora_tomas_ibfk_2` FOREIGN KEY (`medicamento_id`) REFERENCES `medicamentos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
INSERT INTO `bitacora_tomas` (`id`, `adulto_mayor_id`, `medicamento_id`, `fecha_hora`) VALUES (1,102,9,'2026-07-05 21:59:20'),(2,102,9,'2026-07-05 21:59:25'),(3,102,9,'2026-07-05 22:27:46'),(4,102,10,'2026-07-05 22:27:55'),(5,102,9,'2026-07-05 22:28:04'),(6,102,9,'2026-07-05 22:31:48'),(7,102,9,'2026-07-05 22:32:01'),(8,102,9,'2026-07-05 22:32:43'),(9,102,9,'2026-07-05 22:46:10'),(10,102,9,'2026-07-05 22:46:17'),(11,109,20,'2026-07-15 01:13:23');
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `historial_tomas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `medicamento_id` int(11) NOT NULL,
  `fecha_toma` date NOT NULL,
  `hora_toma` time NOT NULL,
  `fecha_registro` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `medicamento_id` (`medicamento_id`),
  CONSTRAINT `historial_tomas_ibfk_1` FOREIGN KEY (`medicamento_id`) REFERENCES `medicamentos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
INSERT INTO `historial_tomas` (`id`, `medicamento_id`, `fecha_toma`, `hora_toma`, `fecha_registro`) VALUES (7,37,'2026-07-14','08:30:00','2026-07-15 05:21:07'),(8,38,'2026-07-14','14:15:00','2026-07-15 05:21:07'),(9,37,'2026-07-13','08:30:00','2026-07-15 05:21:07'),(10,38,'2026-07-13','14:15:00','2026-07-15 05:21:07'),(11,37,'2026-07-12','08:30:00','2026-07-15 05:21:07'),(12,37,'2026-07-14','08:15:00','2026-07-15 05:28:33'),(13,41,'2026-07-14','08:15:00','2026-07-15 05:28:33'),(14,46,'2026-07-14','08:15:00','2026-07-15 05:28:33'),(15,38,'2026-07-14','14:10:00','2026-07-15 05:28:33'),(16,42,'2026-07-14','14:10:00','2026-07-15 05:28:33'),(17,47,'2026-07-14','14:10:00','2026-07-15 05:28:33'),(18,37,'2026-07-13','08:10:00','2026-07-15 05:28:33'),(19,41,'2026-07-13','08:10:00','2026-07-15 05:28:33'),(20,46,'2026-07-13','08:10:00','2026-07-15 05:28:33'),(21,38,'2026-07-13','14:05:00','2026-07-15 05:28:33'),(22,42,'2026-07-13','14:05:00','2026-07-15 05:28:33'),(23,47,'2026-07-13','14:05:00','2026-07-15 05:28:33'),(24,37,'2026-07-12','08:20:00','2026-07-15 05:28:33'),(25,41,'2026-07-12','08:20:00','2026-07-15 05:28:33'),(26,46,'2026-07-12','08:20:00','2026-07-15 05:28:33'),(28,51,'2026-07-15','07:33:33','2026-07-15 05:33:33'),(29,51,'2026-07-15','07:33:42','2026-07-15 05:33:42'),(30,51,'2026-07-15','07:33:45','2026-07-15 05:33:45'),(31,51,'2026-07-15','07:33:46','2026-07-15 05:33:46'),(32,51,'2026-07-15','07:33:57','2026-07-15 05:33:57'),(33,52,'2026-07-15','07:35:14','2026-07-15 05:35:14'),(34,53,'2026-07-15','07:35:26','2026-07-15 05:35:26'),(35,52,'2026-07-15','07:45:29','2026-07-15 05:45:29'),(36,52,'2026-07-15','07:45:35','2026-07-15 05:45:35'),(37,55,'2026-07-15','15:22:09','2026-07-15 13:22:09');
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `medicamentos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `adulto_mayor_id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `dosis` varchar(50) NOT NULL,
  `horario` time NOT NULL,
  `recurrencia_horas` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `adulto_mayor_id` (`adulto_mayor_id`),
  CONSTRAINT `medicamentos_ibfk_1` FOREIGN KEY (`adulto_mayor_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=58 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
INSERT INTO `medicamentos` (`id`, `adulto_mayor_id`, `nombre`, `dosis`, `horario`, `recurrencia_horas`) VALUES (7,100,'Estracto de mi trozon','1 cada 2 horas','08:00:00',0),(9,102,'2','e','08:00:00',0),(10,102,'hola','gola','08:00:00',0),(11,102,'1','1','08:00:00',0),(15,106,'hosn','jgjf','06:00:00',0),(16,13,'hola','hola','08:00:00',8),(18,15,'hola','hola','00:00:00',8),(19,42,'Agua','100ml','02:00:00',0),(20,109,'agua','100ml','07:26:52',4),(22,110,'agua','100ml','08:00:00',8),(23,3,'hola','100ml','08:00:00',8),(37,2,'Paracetamol','1 tableta de 500mg','08:00:00',0),(38,2,'Metformina','1 tableta de 850mg','14:00:00',0),(39,2,'Losartán','1 tableta de 50mg','20:00:00',0),(41,2,'Paracetamol','1 tableta de 500mg','08:00:00',0),(42,2,'Metformina','1 tableta de 850mg','14:00:00',0),(43,2,'Losartán','1 tableta de 50mg','20:00:00',0),(44,2,'Omeprazol','1 cápsula de 20mg','07:00:00',0),(45,2,'Aspirina','1 tableta de 100mg','10:00:00',0),(46,2,'Paracetamol','1 tableta de 500mg','08:00:00',0),(47,2,'Metformina','1 tableta de 850mg','14:00:00',0),(48,2,'Losartán','1 tableta de 50mg','20:00:00',0),(49,2,'Omeprazol','1 cápsula de 20mg','07:00:00',0),(50,2,'Aspirina','1 tableta de 100mg','10:00:00',0),(51,113,'Agua','100ml','23:33:00',4),(52,113,'p','p','08:00:00',8),(53,113,'h','h','23:00:00',8),(54,112,'agua','10ml','08:00:00',8),(55,113,'Agua','250ml','07:00:00',0),(56,114,'gk','gk','08:00:00',8);
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombre` varchar(100) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `telefono` varchar(15) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `rol` enum('administrador','familiar','adulto_mayor') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `estado` varchar(20) DEFAULT 'pendiente',
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=154 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
INSERT INTO `usuarios` (`id`, `nombre`, `email`, `telefono`, `password`, `rol`, `created_at`, `estado`) VALUES (1,'Administrador Derek','admin@derek.com',NULL,'$2y$10$Jv1rgnZeSf/7TdrGNcxpdOLvCpwNOOWrkUSoDJohgpJ19z44pXflm','administrador','2026-06-23 02:26:25','pendiente'),(2,'Familiar Ejemplo','familiar@gmail.com',NULL,'$2y$10$B9L9yG/AxEfuilcshVQfBOcmO6251ImJi3H4ZidncWDSUTgM8gq7S','familiar','2026-06-23 02:26:25','pendiente'),(3,'derek',NULL,NULL,NULL,'adulto_mayor','2026-06-23 02:31:08','pendiente'),(4,'derek',NULL,NULL,NULL,'adulto_mayor','2026-06-23 02:32:15','pendiente'),(13,'lola',NULL,NULL,NULL,'adulto_mayor','2026-06-23 03:16:57','pendiente'),(15,'ceferino',NULL,NULL,NULL,'adulto_mayor','2026-06-23 03:20:41','activo'),(16,'marga',NULL,NULL,NULL,'administrador','2026-06-23 03:29:01','activo'),(17,'Margarita',NULL,NULL,NULL,'administrador','2026-06-23 03:35:56','activo'),(18,'Gael',NULL,NULL,NULL,'administrador','2026-06-23 03:45:30','activo'),(19,'Gael Montes',NULL,NULL,NULL,'administrador','2026-06-23 03:46:34','pendiente'),(20,'gael',NULL,NULL,NULL,'administrador','2026-06-23 03:48:20','pendiente'),(38,'hh',NULL,NULL,NULL,'adulto_mayor','2026-06-23 04:20:48','pendiente'),(40,'miguel',NULL,NULL,NULL,'adulto_mayor','2026-06-23 04:23:43','pendiente'),(41,'kevin',NULL,NULL,NULL,'adulto_mayor','2026-06-23 04:35:18','pendiente'),(42,'Maestra Margarita',NULL,NULL,NULL,'adulto_mayor','2026-06-23 05:13:29','pendiente'),(43,'Ejemplo',NULL,NULL,NULL,'adulto_mayor','2026-06-23 05:20:46','pendiente'),(100,'Jochis',NULL,NULL,NULL,'adulto_mayor','2026-07-05 21:00:53','pendiente'),(101,'Jose Perez','jose@gmail.com',NULL,'$2y$10$wSSNQJoWk57W4g0TfSLC1OWCOtSO//u.RZs2vC1JBLK5KxISA5DLe','familiar','2026-07-05 21:12:21','activo'),(102,'Leonardo',NULL,NULL,NULL,'adulto_mayor','2026-07-05 21:22:58','pendiente'),(103,'Gael','gael@gmail.com',NULL,'$2y$10$0mtyxoHULD6H8ktIC8CtNuLiK7mu93TTCwTZN6n7Cvjb409QSekgm','familiar','2026-07-05 22:42:36','activo'),(104,'Dana',NULL,NULL,NULL,'adulto_mayor','2026-07-14 07:20:14','pendiente'),(105,'Dana','dana@gmail.com',NULL,'$2y$10$j7MEXAllorGBamaS4rs9B.k0MSSCqrhReeXBPwoEtw0azMHdn.9Ui','familiar','2026-07-14 07:22:45','activo'),(106,'Jose',NULL,NULL,NULL,'adulto_mayor','2026-07-14 07:23:18','pendiente'),(107,'gael','gael123@gmail.com',NULL,'$2y$10$vb1fh4tlJBuCmFC750GBvuV2PR.JjvE3B6AGhYuzWXdWEDIn1RjFS','familiar','2026-07-14 14:08:19','activo'),(108,'Jochis',NULL,NULL,NULL,'adulto_mayor','2026-07-14 14:25:53','pendiente'),(109,'Prueba',NULL,NULL,NULL,'adulto_mayor','2026-07-15 01:06:13','pendiente'),(110,'Adrian',NULL,NULL,NULL,'adulto_mayor','2026-07-15 01:28:56','pendiente'),(111,'Jhon','jhon@gmail.com',NULL,'$2y$10$eMdfrd6GTMbwaQ11f8JPvOCCby9h2rAvr6y6upSXRHFRWdlJfFFca','familiar','2026-07-15 01:54:10','activo'),(112,'Tío Miguel',NULL,NULL,NULL,'adulto_mayor','2026-07-15 01:54:26','pendiente'),(113,'Jorge',NULL,NULL,NULL,'adulto_mayor','2026-07-15 02:56:50','pendiente'),(114,'PruebaF',NULL,NULL,NULL,'adulto_mayor','2026-07-15 13:35:04','pendiente'),(123,'Adriana','adriana@gmail.com','5512123434','$2y$10$vP3PZ6O9Q.J0C.gTzW.NzeH7eYJ3E5xY7O/vE7R6Q8k2R5F6G7H8I','familiar','2026-09-22 02:16:14','pendiente'),(150,'prueba','prueba123@gmail.com','55123','$2y$10$LlDui1Wu7e8NNOHEmtB8K.Tal1obTofuXVhY7pwTJEEz/nVYomabW','administrador','2026-09-22 03:03:49','pendiente'),(152,'Adriana Prueba','adriana.prueba@gmail.com','5523568974','$2y$10$XoxXpx9NBfE/SGFryj.8we5H6/8T5oLBknLDGG.27BbpY4dM7Uqru','familiar','2026-10-01 01:02:01','activo');
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `vinculaciones` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `familiar_id` int(11) NOT NULL,
  `adulto_mayor_id` int(11) NOT NULL,
  `codigo_vinculacion` varchar(6) NOT NULL,
  `estado` enum('pendiente','activo') DEFAULT 'pendiente',
  `fecha_vinculacion` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `familiar_id` (`familiar_id`),
  KEY `adulto_mayor_id` (`adulto_mayor_id`),
  CONSTRAINT `vinculaciones_ibfk_1` FOREIGN KEY (`familiar_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE,
  CONSTRAINT `vinculaciones_ibfk_2` FOREIGN KEY (`adulto_mayor_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
INSERT INTO `vinculaciones` (`id`, `familiar_id`, `adulto_mayor_id`, `codigo_vinculacion`, `estado`, `fecha_vinculacion`) VALUES (1,2,3,'','pendiente','2026-06-23 02:31:08'),(2,2,4,'','pendiente','2026-06-23 02:32:15'),(11,2,13,'','pendiente','2026-06-23 03:16:57'),(13,2,15,'','pendiente','2026-06-23 03:20:41'),(25,2,38,'201553','pendiente','2026-06-23 04:20:48'),(27,2,40,'040697','pendiente','2026-06-23 04:23:43'),(28,2,41,'772762','activo','2026-06-23 04:35:18'),(29,2,42,'868819','activo','2026-06-23 05:13:29'),(30,2,43,'125659','activo','2026-06-23 05:20:46'),(32,101,102,'442096','activo','2026-07-05 21:22:58'),(33,2,104,'208800','activo','2026-07-14 07:20:14'),(34,105,106,'831731','pendiente','2026-07-14 07:23:18'),(35,2,108,'056744','activo','2026-07-14 14:25:53'),(36,2,109,'558294','activo','2026-07-15 01:06:13'),(37,2,110,'187716','activo','2026-07-15 01:28:56'),(38,111,112,'914944','activo','2026-07-15 01:54:26'),(39,111,113,'650226','activo','2026-07-15 02:56:50'),(40,2,114,'010691','pendiente','2026-07-15 13:35:04');
