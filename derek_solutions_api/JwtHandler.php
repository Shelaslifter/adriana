<?php
class JwtHandler {
    private static function base64UrlEncode($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function base64UrlDecode($data) {
        return base64_decode(strtr($data, '-_', '+/'));
    }

    // Generar Token JWT
    public static function generarToken($dataUsuario, $secretKey, $expiracionHoras = 8) {
        $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
        
        $time = time();
        $payload = json_encode([
            'iat' => $time,                       // Tiempo de emisión
            'exp' => $time + ($expiracionHoras * 3600), // Expiración (8 horas)
            'data' => $dataUsuario                // Información del usuario (id, email, rol)
        ]);

        $base64UrlHeader  = self::base64UrlEncode($header);
        $base64UrlPayload = self::base64UrlEncode($payload);

        $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, $secretKey, true);
        $base64UrlSignature = self::base64UrlEncode($signature);

        return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
    }

    // Validar Token JWT
    public static function verificarToken($jwt, $secretKey) {
        $tokenParts = explode('.', $jwt);
        if (count($tokenParts) !== 3) return false;

        $header    = self::base64UrlDecode($tokenParts[0]);
        $payload   = self::base64UrlDecode($tokenParts[1]);
        $signature = $tokenParts[2];

        $validSignature = self::base64UrlEncode(
            hash_hmac('sha256', $tokenParts[0] . "." . $tokenParts[1], $secretKey, true)
        );

        if (!hash_equals($validSignature, $signature)) {
            return false; // Firma inválida
        }

        $payloadData = json_decode($payload, true);

        // Verificar si el token ya expiró
        if (isset($payloadData['exp']) && $payloadData['exp'] < time()) {
            return false; // Token expirado
        }

        return $payloadData['data']; // Devuelve la información del usuario si es válido
    }
}
?>