<?php

use App\Http\Controllers\Admin\RoleController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\AnnouncementController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\DocumentController;
use App\Http\Controllers\LetterActivePeriodController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\TaskController;
use App\Http\Controllers\TodoController;
use App\Http\Controllers\WorkDocumentController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/tasks/shared/{token}', [TaskController::class, 'showShared'])->name('tasks.shared.show');
Route::post('/tasks/shared/{token}/comments', [TaskController::class, 'storeComment'])->name('tasks.shared.comments');

Route::get('/dashboard', [DashboardController::class, 'index'])
    ->middleware(['auth', 'verified'])->name('dashboard');

Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');

    Route::middleware(['role:super_admin|administrasi|teknisi|logistic'])->group(function () {
        Route::get('tasks', [TaskController::class, 'index'])->name('tasks.index');
        Route::get('tasks/create', [TaskController::class, 'create'])->name('tasks.create')->middleware('permission:task-create');
        Route::post('tasks', [TaskController::class, 'store'])->name('tasks.store')->middleware('permission:task-create');
        Route::get('tasks/{task}', [TaskController::class, 'show'])->name('tasks.show');
        Route::get('tasks/{task}/edit', [TaskController::class, 'edit'])->name('tasks.edit')->middleware('permission:task-edit');
        Route::patch('tasks/{task}', [TaskController::class, 'update'])->name('tasks.update')->middleware('permission:task-edit');
        Route::delete('tasks/{task}', [TaskController::class, 'destroy'])->name('tasks.destroy')->middleware('permission:task-delete');
        Route::post('tasks/{task}/shopping-items', [TaskController::class, 'storeShoppingItem'])->name('tasks.shopping-items.store');
        Route::patch('tasks/{task}/shopping-items/{item}/toggle', [TaskController::class, 'toggleShoppingItem'])->name('tasks.shopping-items.toggle');
        Route::post('tasks/{task}/shopping-items/{item}/image', [TaskController::class, 'uploadShoppingItemImage'])->name('tasks.shopping-items.image');
        Route::delete('tasks/{task}/shopping-items/{item}/image', [TaskController::class, 'destroyShoppingItemImage'])->name('tasks.shopping-items.image.destroy');
        Route::patch('tasks/{task}/shopping-items/{item}', [TaskController::class, 'updateShoppingItem'])->name('tasks.shopping-items.update');
        Route::delete('tasks/{task}/shopping-items/{item}', [TaskController::class, 'destroyShoppingItem'])->name('tasks.shopping-items.destroy');
        Route::patch('tasks/{task}/status', [TaskController::class, 'updateStatus'])->name('tasks.status.update');
        Route::post('tasks/{task}/teknisi-items', [TaskController::class, 'storeTeknisiTaskItem'])->name('tasks.teknisi-items.store');
        Route::patch('tasks/{task}/teknisi-items/{item}/toggle', [TaskController::class, 'toggleTeknisiTaskItem'])->name('tasks.teknisi-items.toggle');
        Route::post('tasks/{task}/teknisi-items/{item}/images', [TaskController::class, 'uploadTeknisiTaskItemImage'])->name('tasks.teknisi-items.images.upload');
        Route::delete('tasks/teknisi-items/images/{image}', [TaskController::class, 'destroyTeknisiTaskItemImage'])->name('tasks.teknisi-items.images.destroy');
        Route::patch('tasks/{task}/teknisi-items/{item}', [TaskController::class, 'updateTeknisiTaskItem'])->name('tasks.teknisi-items.update');
        Route::delete('tasks/{task}/teknisi-items/{item}', [TaskController::class, 'destroyTeknisiTaskItem'])->name('tasks.teknisi-items.destroy');
        Route::post('tasks/{task}/share-link', [TaskController::class, 'generateShareLink'])->name('tasks.share-link');
        Route::post('tasks/{task}/comments/{comment}/reply', [TaskController::class, 'replyComment'])->name('tasks.comments.reply');

        Route::get('announcements/create', [AnnouncementController::class, 'create'])->name('announcements.create')->middleware('role:super_admin');
        Route::post('announcements', [AnnouncementController::class, 'store'])->name('announcements.store')->middleware('role:super_admin');
        Route::get('announcements', [AnnouncementController::class, 'index'])->name('announcements.index');
        Route::get('announcements/{announcement}/edit', [AnnouncementController::class, 'edit'])->name('announcements.edit')->middleware('role:super_admin');
        Route::patch('announcements/{announcement}', [AnnouncementController::class, 'update'])->name('announcements.update')->middleware('role:super_admin');
        Route::delete('announcements/{announcement}', [AnnouncementController::class, 'destroy'])->name('announcements.destroy')->middleware('role:super_admin');
        Route::get('announcements/{announcement}', [AnnouncementController::class, 'show'])->name('announcements.show');
    });

    Route::middleware(['role:super_admin|administrasi|teknisi|logistic'])->group(function () {
        Route::get('documents/create', [DocumentController::class, 'create'])->name('documents.create')->middleware('role:super_admin|administrasi');
        Route::post('documents', [DocumentController::class, 'store'])->name('documents.store')->middleware('role:super_admin|administrasi');
        Route::get('documents', [DocumentController::class, 'index'])->name('documents.index');
        Route::get('documents/{document}/edit', [DocumentController::class, 'edit'])->name('documents.edit')->middleware('role:super_admin|administrasi');
        Route::patch('documents/{document}', [DocumentController::class, 'update'])->name('documents.update')->middleware('role:super_admin|administrasi');
        Route::delete('documents/{document}', [DocumentController::class, 'destroy'])->name('documents.destroy')->middleware('role:super_admin|administrasi');
        Route::get('documents/{document}', [DocumentController::class, 'show'])->name('documents.show');
    });

    Route::middleware(['role:super_admin|administrasi'])->prefix('admin')->name('admin.')->group(function () {
        Route::get('monitoring/logistic', [DashboardController::class, 'monitoringLogistic'])->name('monitoring.logistic');
        Route::get('monitoring/teknisi', [DashboardController::class, 'monitoringTeknisi'])->name('monitoring.teknisi');
    });

    Route::middleware(['role:super_admin|administrasi'])->group(function () {
        Route::get('todos', [TodoController::class, 'index'])->name('todos.index');
        Route::post('todos', [TodoController::class, 'store'])->name('todos.store');
        Route::delete('todos/{todo}', [TodoController::class, 'destroy'])->name('todos.destroy');
        Route::patch('todos/{todo}/toggle-status', [TodoController::class, 'toggleStatus'])->name('todos.toggle-status');
    });

    Route::middleware(['role:super_admin|administrasi'])->group(function () {
        Route::get('letter-active-periods', [LetterActivePeriodController::class, 'index'])->name('letter-active-periods.index');
        Route::get('letter-active-periods/create', [LetterActivePeriodController::class, 'create'])->name('letter-active-periods.create');
        Route::post('letter-active-periods', [LetterActivePeriodController::class, 'store'])->name('letter-active-periods.store');
        Route::get('letter-active-periods/{letterActivePeriod}/edit', [LetterActivePeriodController::class, 'edit'])->name('letter-active-periods.edit');
        Route::patch('letter-active-periods/{letterActivePeriod}', [LetterActivePeriodController::class, 'update'])->name('letter-active-periods.update');
        Route::delete('letter-active-periods/{letterActivePeriod}', [LetterActivePeriodController::class, 'destroy'])->name('letter-active-periods.destroy');
    });

    Route::middleware(['role:super_admin|administrasi'])->group(function () {
        Route::get('work-documents', [WorkDocumentController::class, 'index'])->name('work-documents.index');
        Route::post('work-documents', [WorkDocumentController::class, 'store'])->name('work-documents.store');
        Route::get('work-documents/{task}/document', [WorkDocumentController::class, 'getDocument'])->name('work-documents.document');
        Route::delete('work-documents/{task}', [WorkDocumentController::class, 'destroy'])->name('work-documents.destroy');
        Route::delete('work-documents/{task}/file', [WorkDocumentController::class, 'destroyFile'])->name('work-documents.file.destroy');
    });

    Route::middleware(['role:super_admin'])->prefix('admin')->name('admin.')->group(function () {
        Route::resource('users', UserController::class)->except(['show']);
        Route::get('roles', [RoleController::class, 'index'])->name('roles.index');
        Route::post('roles', [RoleController::class, 'store'])->name('roles.store');
        Route::patch('roles/{role}/permissions', [RoleController::class, 'updatePermissions'])->name('roles.permissions.update');
        Route::delete('roles/{role}', [RoleController::class, 'destroy'])->name('roles.destroy');
    });
});

require __DIR__.'/auth.php';
