-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 23-06-2026 a las 07:27:03
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `derek_solutions_db`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `medicamentos`
--

CREATE TABLE `medicamentos` (
  `id` int(11) NOT NULL,
  `adulto_mayor_id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `dosis` varchar(50) NOT NULL,
  `horario` time NOT NULL,
  `recurrencia_horas` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `medicamentos`
--

INSERT INTO `medicamentos` (`id`, `adulto_mayor_id`, `nombre`, `dosis`, `horario`, `recurrencia_horas`) VALUES
(4, 41, 'agua', 'todo el dia', '08:00:00', 0),
(5, 42, 'agua', '100ml', '01:00:00', 0),
(6, 43, 'té', '100ml', '08:00:00', 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `email` varchar(100) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `rol` enum('administrador','familiar','adulto_mayor') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `estado` varchar(20) DEFAULT 'pendiente'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id`, `nombre`, `email`, `password`, `rol`, `created_at`, `estado`) VALUES
(1, 'Administrador Derek', 'admin@derek.com', 'password123', 'administrador', '2026-06-23 02:26:25', 'pendiente'),
(2, 'Familiar Ejemplo', 'familiar@gmail.com', 'password123', 'familiar', '2026-06-23 02:26:25', 'pendiente'),
(3, 'derek', NULL, NULL, 'adulto_mayor', '2026-06-23 02:31:08', 'pendiente'),
(4, 'derek', NULL, NULL, 'adulto_mayor', '2026-06-23 02:32:15', 'pendiente'),
(13, 'lola', NULL, NULL, 'adulto_mayor', '2026-06-23 03:16:57', 'pendiente'),
(15, 'ceferino', NULL, NULL, 'adulto_mayor', '2026-06-23 03:20:41', 'activo'),
(16, 'marga', NULL, NULL, 'administrador', '2026-06-23 03:29:01', 'activo'),
(17, 'Margarita', NULL, NULL, 'administrador', '2026-06-23 03:35:56', 'activo'),
(18, 'Gael', NULL, NULL, 'administrador', '2026-06-23 03:45:30', 'activo'),
(19, 'Gael Montes', NULL, NULL, 'administrador', '2026-06-23 03:46:34', 'pendiente'),
(20, 'gael', NULL, NULL, 'administrador', '2026-06-23 03:48:20', 'pendiente'),
(21, 'pedro', NULL, NULL, 'administrador', '2026-06-23 03:52:42', 'activo'),
(27, 'jorge', NULL, NULL, 'adulto_mayor', '2026-06-23 03:58:42', 'pendiente'),
(28, 'miguelito', NULL, NULL, 'adulto_mayor', '2026-06-23 04:01:47', 'pendiente'),
(35, 'derek solutions', NULL, NULL, 'adulto_mayor', '2026-06-23 04:13:26', 'pendiente'),
(36, 'don miguel', NULL, NULL, 'adulto_mayor', '2026-06-23 04:15:54', 'pendiente'),
(37, 'Teo', NULL, NULL, 'adulto_mayor', '2026-06-23 04:20:31', 'pendiente'),
(38, 'hh', NULL, NULL, 'adulto_mayor', '2026-06-23 04:20:48', 'pendiente'),
(39, 'derek123', NULL, NULL, 'adulto_mayor', '2026-06-23 04:21:42', 'pendiente'),
(40, 'miguel', NULL, NULL, 'adulto_mayor', '2026-06-23 04:23:43', 'pendiente'),
(41, 'kevin', NULL, NULL, 'adulto_mayor', '2026-06-23 04:35:18', 'pendiente'),
(42, 'Maestra Margarita', NULL, NULL, 'adulto_mayor', '2026-06-23 05:13:29', 'pendiente'),
(43, 'Ejemplo', NULL, NULL, 'adulto_mayor', '2026-06-23 05:20:46', 'pendiente');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculaciones`
--

CREATE TABLE `vinculaciones` (
  `id` int(11) NOT NULL,
  `familiar_id` int(11) NOT NULL,
  `adulto_mayor_id` int(11) NOT NULL,
  `codigo_vinculacion` varchar(6) NOT NULL,
  `estado` enum('pendiente','activo') DEFAULT 'pendiente',
  `fecha_vinculacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `vinculaciones`
--

INSERT INTO `vinculaciones` (`id`, `familiar_id`, `adulto_mayor_id`, `codigo_vinculacion`, `estado`, `fecha_vinculacion`) VALUES
(1, 2, 3, '', 'pendiente', '2026-06-23 02:31:08'),
(2, 2, 4, '', 'pendiente', '2026-06-23 02:32:15'),
(11, 2, 13, '', 'pendiente', '2026-06-23 03:16:57'),
(13, 2, 15, '', 'pendiente', '2026-06-23 03:20:41'),
(14, 2, 27, '', 'pendiente', '2026-06-23 03:58:42'),
(15, 2, 28, '', 'pendiente', '2026-06-23 04:01:47'),
(22, 2, 35, '', 'pendiente', '2026-06-23 04:13:26'),
(23, 2, 36, '068150', 'pendiente', '2026-06-23 04:15:54'),
(24, 2, 37, '278176', 'pendiente', '2026-06-23 04:20:31'),
(25, 2, 38, '201553', 'pendiente', '2026-06-23 04:20:48'),
(26, 2, 39, '868503', 'pendiente', '2026-06-23 04:21:42'),
(27, 2, 40, '040697', 'pendiente', '2026-06-23 04:23:43'),
(28, 2, 41, '772762', 'activo', '2026-06-23 04:35:18'),
(29, 2, 42, '868819', 'activo', '2026-06-23 05:13:29'),
(30, 2, 43, '125659', 'activo', '2026-06-23 05:20:46');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `medicamentos`
--
ALTER TABLE `medicamentos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `adulto_mayor_id` (`adulto_mayor_id`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indices de la tabla `vinculaciones`
--
ALTER TABLE `vinculaciones`
  ADD PRIMARY KEY (`id`),
  ADD KEY `familiar_id` (`familiar_id`),
  ADD KEY `adulto_mayor_id` (`adulto_mayor_id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `medicamentos`
--
ALTER TABLE `medicamentos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;

--
-- AUTO_INCREMENT de la tabla `vinculaciones`
--
ALTER TABLE `vinculaciones`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `medicamentos`
--
ALTER TABLE `medicamentos`
  ADD CONSTRAINT `medicamentos_ibfk_1` FOREIGN KEY (`adulto_mayor_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `vinculaciones`
--
ALTER TABLE `vinculaciones`
  ADD CONSTRAINT `vinculaciones_ibfk_1` FOREIGN KEY (`familiar_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `vinculaciones_ibfk_2` FOREIGN KEY (`adulto_mayor_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
