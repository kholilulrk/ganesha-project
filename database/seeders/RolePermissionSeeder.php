<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class RolePermissionSeeder extends Seeder
{
    public function run(): void
    {
        $permissions = [
            'task-list',
            'task-create',
            'task-edit',
            'task-delete',
        ];

        foreach ($permissions as $name) {
            Permission::firstOrCreate(['name' => $name, 'guard_name' => 'web']);
        }

        $superAdmin = Role::firstOrCreate(['name' => 'super_admin', 'guard_name' => 'web']);
        $administrasi = Role::firstOrCreate(['name' => 'administrasi', 'guard_name' => 'web']);
        $teknisi = Role::firstOrCreate(['name' => 'teknisi', 'guard_name' => 'web']);
        $logistic = Role::firstOrCreate(['name' => 'logistic', 'guard_name' => 'web']);

        $superAdmin->syncPermissions(Permission::all());
        $administrasi->syncPermissions($permissions);
        $teknisi->syncPermissions(['task-list']);
        $logistic->syncPermissions(['task-list']);

        $superAdminUser = User::firstOrCreate(
            ['email' => 'superadmin@ganesha.test'],
            [
                'name' => 'Super Admin',
                'password' => bcrypt('password'),
            ]
        );
        $superAdminUser->assignRole('super_admin');
    }
}
