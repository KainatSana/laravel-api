<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('vehicles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('customer_id')->constrained('customers')->onDelete('cascade');
            $table->string('vin')->unique();
            $table->string('license_plate')->unique();
            $table->year('year');
            $table->string('make');
            $table->string('model');
            $table->string('trim')->nullable();
            $table->string('color')->nullable();
            $table->enum('transmission', ['automatic', 'manual'])->nullable();
            $table->integer('mileage')->nullable();
            $table->timestamp('last_service_date')->nullable();
            $table->enum('status', ['active', 'retired', 'archived'])->default('active');
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index('vin');
            $table->index('license_plate');
            $table->index('customer_id');
            $table->index('status');
        });
    }

    public function down()
    {
        Schema::dropIfExists('vehicles');
    }
};
