<?php

namespace App\Services;

use App\Models\DeviceToken;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Exception\Messaging\NotFound;
use Kreait\Firebase\Exception\MessagingException;
use Kreait\Firebase\Messaging\AndroidConfig;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;
use Kreait\Laravel\Firebase\Facades\Firebase;
use Throwable;

class FcmNotificationService
{
    private const ANDROID_CHANNEL_ID = 'attendance_reminder';

    private const ANDROID_NOTIFICATION_ICON = 'ic_stat_attendify';

    public function sendToToken(
        string $token,
        string $title,
        string $body,
        array $data = []
    ): bool {
        try {
            $stringData = collect($data)
                ->mapWithKeys(
                    fn($value, $key) => [
                        (string) $key => (string) $value,
                    ]
                )
                ->all();

            $androidConfig = AndroidConfig::fromArray([
                'priority' => 'high',
                'notification' => [
                    'channel_id' => self::ANDROID_CHANNEL_ID,
                    'icon' => self::ANDROID_NOTIFICATION_ICON,
                    'sound' => 'default',
                ],
            ]);

            $message = CloudMessage::new()
                ->withToken($token)
                ->withNotification(
                    Notification::create(
                        $title,
                        $body
                    )
                )
                ->withData($stringData)
                ->withAndroidConfig($androidConfig);

            Firebase::messaging()->send($message);

            return true;
        } catch (NotFound $exception) {
            DeviceToken::query()
                ->where('token', $token)
                ->delete();

            Log::warning(
                'Token FCM tidak valid dan telah dihapus.',
                [
                    'token_suffix' => substr($token, -12),
                    'message' => $exception->getMessage(),
                ]
            );

            return false;
        } catch (MessagingException $exception) {
            Log::error(
                'Firebase Messaging Error',
                [
                    'token_suffix' => substr($token, -12),
                    'message' => $exception->getMessage(),
                ]
            );

            return false;
        } catch (Throwable $exception) {
            Log::error(
                'Gagal mengirim notifikasi FCM',
                [
                    'token_suffix' => substr($token, -12),
                    'message' => $exception->getMessage(),
                ]
            );

            return false;
        }
    }

    public function sendToTokens(
        iterable $tokens,
        string $title,
        string $body,
        array $data = []
    ): array {
        $sent = 0;
        $failed = 0;

        foreach ($tokens as $token) {
            $success = $this->sendToToken(
                $token,
                $title,
                $body,
                $data
            );

            if ($success) {
                $sent++;
            } else {
                $failed++;
            }
        }

        return [
            'sent' => $sent,
            'failed' => $failed,
        ];
    }
}
