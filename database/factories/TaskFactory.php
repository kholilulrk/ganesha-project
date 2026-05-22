<?php

namespace Database\Factories;

use App\Models\Task;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class TaskFactory extends Factory
{
    protected $model = Task::class;

    public function definition(): array
    {
        return [
            'title' => fake()->sentence(4),
            'description' => fake()->paragraph(),
            'task_type' => fake()->randomElement(['teknisi', 'logistic']),
            'status' => fake()->randomElement(['pending', 'progress', 'done', 'cancelled']),
            'priority' => fake()->randomElement(['low', 'medium', 'high']),
            'deadline' => fake()->dateTimeBetween('now', '+30 days'),
            'created_by' => User::factory(),
        ];
    }

    public function configure(): static
    {
        return $this->afterCreating(function (Task $task) {
            $users = User::inRandomOrder()->take(rand(1, 2))->get();
            if ($users->isNotEmpty()) {
                $task->assignedUsers()->sync($users->pluck('id'));
            }
        });
    }
}
