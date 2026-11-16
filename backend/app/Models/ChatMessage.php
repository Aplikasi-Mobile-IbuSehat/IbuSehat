<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Satu giliran dalam sesi chat (role: user | model).
 */
class ChatMessage extends Model
{
    public const ROLE_USER  = 'user';
    public const ROLE_MODEL = 'model';

    public const KIND_CHAT      = 'chat';
    public const KIND_EMERGENCY = 'emergency';

    public const UPDATED_AT = null;

    protected $fillable = [
        'chat_session_id',
        'role',
        'content',
        'kind',
    ];

    protected $casts = [
        'created_at' => 'datetime',
    ];

    public function session(): BelongsTo
    {
        return $this->belongsTo(ChatSession::class, 'chat_session_id');
    }
}
