<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('reward_cards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('customers')->onDelete('cascade');
            $table->string('card_number')->unique();
            $table->string('card_token')->unique()->nullable();
            $table->decimal('balance', 10, 2)->default(0);
            $table->decimal('lifetime_earned', 10, 2)->default(0);
            $table->decimal('lifetime_redeemed', 10, 2)->default(0);
            $table->enum('status', ['active', 'suspended', 'expired', 'cancelled'])->default('active');
            $table->dateTime('issued_at')->nullable();
            $table->dateTime('expires_at')->nullable();
            $table->dateTime('last_used_at')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index('customer_id');
            $table->index('card_number');
            $table->index('status');
        });
    }

    public function down()
    {
        Schema::dropIfExists('reward_cards');
    }
};
