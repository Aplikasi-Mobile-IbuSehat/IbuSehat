<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CompleteWorkoutRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true; // Authorization handled by auth:sanctum middleware
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'workout_id' => 'required|integer',
        ];
    }

    /**
     * Get custom error messages
     */
    public function messages(): array
    {
        return [
            'workout_id.integer' => 'ID workout harus berupa angka.',
        ];
    }
}
