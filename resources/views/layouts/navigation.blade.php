<nav x-data="{ open: false }" class="lg:flex">
    {{-- Mobile overlay --}}
    <div x-show="open" x-on:click="open = false" x-cloak class="fixed inset-0 z-20 bg-black/60 lg:hidden"></div>

    {{-- Mobile hamburger --}}
    <div class="fixed top-0 left-0 z-10 lg:hidden" :class="{ 'hidden': open }">
        <button @click="open = true" class="m-3 p-2 rounded-md text-indigo-600 bg-white shadow-md hover:bg-indigo-50 focus:outline-none transition">
            <svg class="h-6 w-6" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
        </button>
    </div>

    {{-- Sidebar panel --}}
    <div class="fixed inset-y-0 left-0 z-30 w-64 bg-gradient-to-b from-indigo-700 to-indigo-900 flex flex-col transform transition-transform duration-300 ease-in-out lg:translate-x-0 shadow-xl"
         :class="open ? 'translate-x-0' : '-translate-x-full'">

        {{-- Logo --}}
        <div class="flex items-center justify-between h-16 px-4 border-b border-white/10 shrink-0">
            <a href="{{ route('dashboard') }}" class="flex items-center gap-2">
                <div class="w-8 h-8 rounded-lg bg-white/20 flex items-center justify-center">
                    <x-application-logo class="block h-5 w-auto fill-current text-white" />
                </div>
                <span class="text-sm font-bold text-white truncate tracking-wide">{{ config('app.name', 'Ganesha Project') }}</span>
            </a>
            <button @click="open = false" class="lg:hidden p-1.5 rounded-md text-indigo-200 hover:text-white hover:bg-white/10 transition">
                <svg class="h-5 w-5" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
            </button>
        </div>

        {{-- Nav items --}}
        <div class="flex-1 overflow-y-auto py-4 space-y-1 px-3">
            {{-- Dashboard --}}
            <a href="{{ route('dashboard') }}"
               class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                      {{ request()->routeIs('dashboard') ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-100 hover:text-white hover:bg-white/10' }}">
                <svg class="w-5 h-5 shrink-0" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                </svg>
                <span>Dashboard</span>
            </a>

                {{-- Monitoring (dropdown) --}}
                @auth
                @php $user = auth()->user(); @endphp
                @if($user->hasAnyRole(['super_admin', 'administrasi']))
                @php
                    $teknisiUnfinishedCount = \App\Models\Task::where('task_type', 'teknisi')->whereIn('status', ['pending', 'progress'])->count();
                    $logisticUnfinishedCount = \App\Models\Task::where(function ($q) { $q->whereDoesntHave('shoppingItems')->orWhereHas('shoppingItems', fn($q) => $q->where('is_checked', false)); })->count();
                    $expiringLetterCount = \App\Models\LetterActivePeriod::whereBetween('masa_aktif_berakhir', [
                        now()->startOfDay(),
                        now()->addDays(7)->endOfDay(),
                    ])->count();
                    $monitoringActive = request()->routeIs('admin.monitoring.*') || request()->routeIs('letter-active-periods.*');
                @endphp
                <div x-data="{ open: @json($monitoringActive) }">
                    <button @click.prevent="open = !open"
                            class="flex items-center gap-3 w-full px-3 py-2.5 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                                   {{ $monitoringActive ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-100 hover:text-white hover:bg-white/10' }}">
                        <svg class="w-5 h-5 shrink-0" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                        </svg>
                        <span class="flex-1 text-left">Monitoring</span>
                            @if($teknisiUnfinishedCount + $logisticUnfinishedCount + $expiringLetterCount > 0)
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold bg-white/20 text-white">{{ $teknisiUnfinishedCount + $logisticUnfinishedCount + $expiringLetterCount }}</span>
                            @endif
                        <svg class="w-4 h-4 transition-transform duration-200 text-indigo-300" :class="{ 'rotate-90': open }" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                        </svg>
                    </button>
                    <div x-show="open" x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 scale-95" x-transition:enter-end="opacity-100 scale-100" class="ml-6 mt-1 space-y-1">
                        <a href="{{ route('admin.monitoring.teknisi') }}"
                           class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                                  {{ request()->routeIs('admin.monitoring.teknisi') ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-200 hover:text-white hover:bg-white/10' }}">
                            <div class="w-1.5 h-1.5 rounded-full bg-indigo-300"></div>
                            <span class="flex-1">M. Teknisi</span>
                            @if($teknisiUnfinishedCount > 0)
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold bg-red-400/20 text-red-200">{{ $teknisiUnfinishedCount }}</span>
                            @endif
                        </a>
                        <a href="{{ route('admin.monitoring.logistic') }}"
                           class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                                  {{ request()->routeIs('admin.monitoring.logistic') ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-200 hover:text-white hover:bg-white/10' }}">
                            <div class="w-1.5 h-1.5 rounded-full bg-indigo-300"></div>
                            <span class="flex-1">M. Logistic</span>
                            @if($logisticUnfinishedCount > 0)
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold bg-yellow-400/20 text-yellow-200">{{ $logisticUnfinishedCount }}</span>
                            @endif
                        </a>
                        <a href="{{ route('letter-active-periods.index') }}"
                           class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                                  {{ request()->routeIs('letter-active-periods.*') ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-200 hover:text-white hover:bg-white/10' }}">
                            <div class="w-1.5 h-1.5 rounded-full bg-indigo-300"></div>
                            <span class="flex-1">M. Aktif Surat</span>
                            @if($expiringLetterCount > 0)
                                <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold bg-red-400/20 text-red-200">{{ $expiringLetterCount }}</span>
                            @endif
                        </a>
                    </div>
                </div>
                @endif

                {{-- Pekerjaan (dropdown) --}}
                @php $pekerjaanActive = request()->routeIs('tasks.*') || request()->routeIs('work-documents.*') || request()->routeIs('sph.*'); @endphp
                <div x-data="{ open: @json($pekerjaanActive) }">
                    <button @click.prevent="open = !open"
                            class="flex items-center gap-3 w-full px-3 py-2.5 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                                   {{ $pekerjaanActive ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-100 hover:text-white hover:bg-white/10' }}">
                        <svg class="w-5 h-5 shrink-0" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
                        </svg>
                        <span class="flex-1 text-left">Pekerjaan</span>
                        <svg class="w-4 h-4 transition-transform duration-200 text-indigo-300" :class="{ 'rotate-90': open }" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                        </svg>
                    </button>
                    <div x-show="open" x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 scale-95" x-transition:enter-end="opacity-100 scale-100" class="ml-6 mt-1 space-y-1">
                        <a href="{{ route('tasks.index') }}"
                           class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                                  {{ request()->routeIs('tasks.*') ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-200 hover:text-white hover:bg-white/10' }}">
                            <div class="w-1.5 h-1.5 rounded-full bg-indigo-300"></div>
                            <span class="flex-1">Data Pekerjaan</span>
                            @php $role = $user->getRoleNames()->first(); @endphp
                            @if($user->hasRole('teknisi'))
                                @php
                                    $taskCount = \App\Models\Task::where(function ($q) use ($user, $role) {
                                        $q->whereHas('assignedUsers', fn($sub) => $sub->where('user_id', $user->id))
                                          ->orWhere('assigned_role', $role)
                                          ->orWhere(function ($sub) {
                                              $sub->whereDoesntHave('assignedUsers')->whereNull('assigned_role');
                                          });
                                    })->whereIn('status', ['pending', 'progress'])->count();
                                @endphp
                                @if($taskCount > 0)
                                    <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold bg-red-400/20 text-red-200">{{ $taskCount }}</span>
                                @endif
                            @elseif($user->hasRole('logistic'))
                                @php
                                    $shoppingCount = \App\Models\Task::whereHas('shoppingItems', fn($q) => $q->where('is_checked', false))->count();
                                @endphp
                                @if($shoppingCount > 0)
                                    <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold bg-yellow-400/20 text-yellow-200">{{ $shoppingCount }}</span>
                                @endif
                            @endif
                        </a>
                        @if($user->hasAnyRole(['super_admin', 'administrasi']))
                        <a href="{{ route('work-documents.index') }}"
                           class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                                  {{ request()->routeIs('work-documents.*') ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-200 hover:text-white hover:bg-white/10' }}">
                            <div class="w-1.5 h-1.5 rounded-full bg-indigo-300"></div>
                            <span class="flex-1">Kelengkapan Pekerjaan</span>
                        </a>
                        <a href="{{ route('sph.index') }}"
                           class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                                  {{ request()->routeIs('sph.*') ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-200 hover:text-white hover:bg-white/10' }}">
                            <div class="w-1.5 h-1.5 rounded-full bg-indigo-300"></div>
                            <span class="flex-1">Kalkulasi SPH</span>
                        </a>
                        @endif
                    </div>
                </div>

                {{-- Documents --}}
                <a href="{{ route('documents.index') }}"
                   class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                          {{ request()->routeIs('documents.*') ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-100 hover:text-white hover:bg-white/10' }}">
                    <svg class="w-5 h-5 shrink-0" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
                    </svg>
                    <span>Documents</span>
                </a>

                {{-- To-Do --}}
                @if($user->hasAnyRole(['super_admin', 'administrasi']))
                    <a href="{{ route('todos.index') }}"
                       class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                              {{ request()->routeIs('todos.*') ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-100 hover:text-white hover:bg-white/10' }}">
                        <svg class="w-5 h-5 shrink-0" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                        </svg>
                        <span>To-Do</span>
                    </a>
                @endif

                {{-- Activity Log --}}
                @if($user->hasAnyRole(['super_admin', 'administrasi']))
                    <a href="{{ route('activity-logs.index') }}"
                       class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                              {{ request()->routeIs('activity-logs.*') ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-100 hover:text-white hover:bg-white/10' }}">
                        <svg class="w-5 h-5 shrink-0" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        <span>Activity Log</span>
                    </a>
                @endif

                {{-- Pengumuman --}}
                <a href="{{ route('announcements.index') }}"
                   class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                          {{ request()->routeIs('announcements.*') ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-100 hover:text-white hover:bg-white/10' }}">
                    <svg class="w-5 h-5 shrink-0" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5.882V19.24a1.76 1.76 0 01-3.417.592l-2.147-6.15M18 13a3 3 0 100-6M5.436 13.683A4.001 4.001 0 017 6h1.832c4.1 0 7.625-1.234 9.168-3v14c-1.543-1.766-5.067-3-9.168-3H7a3.988 3.988 0 01-1.564-.317z" />
                    </svg>
                    <span class="flex-1">Pengumuman</span>
                    @php
                        $activeAnnouncementCount = $user->hasRole('super_admin')
                            ? \App\Models\Announcement::scheduled()->count()
                            : \App\Models\Announcement::scheduled()->visibleTo($user)->count();
                    @endphp
                    @if($activeAnnouncementCount > 0)
                        <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-bold bg-red-400/20 text-red-200">{{ $activeAnnouncementCount }}</span>
                    @endif
                </a>

                {{-- Settings (dropdown) --}}
                @php $settingsActive = request()->routeIs('profile.*') || request()->is('admin/users*') || request()->routeIs('admin.roles.*'); @endphp
                <div x-data="{ open: @json($settingsActive) }">
                    <button @click.prevent="open = !open"
                            class="flex items-center gap-3 w-full px-3 py-2.5 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                                   {{ $settingsActive ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-100 hover:text-white hover:bg-white/10' }}">
                        <svg class="w-5 h-5 shrink-0" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                        </svg>
                        <span class="flex-1 text-left">Settings</span>
                        <svg class="w-4 h-4 transition-transform duration-200 text-indigo-300" :class="{ 'rotate-90': open }" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                        </svg>
                    </button>
                    <div x-show="open" x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 scale-95" x-transition:enter-end="opacity-100 scale-100" class="ml-6 mt-1 space-y-1">
                        <a href="{{ route('profile.edit') }}"
                           class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                                  {{ request()->routeIs('profile.*') ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-200 hover:text-white hover:bg-white/10' }}">
                            <svg class="w-4 h-4" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                            </svg>
                            <span>Profile</span>
                        </a>
                        @if($user->hasRole('super_admin'))
                        <a href="{{ url('/admin/users') }}"
                           class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                                  {{ request()->is('admin/users*') ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-200 hover:text-white hover:bg-white/10' }}">
                            <svg class="w-4 h-4" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
                            </svg>
                            <span>Users</span>
                        </a>
                        <a href="{{ route('admin.roles.index') }}"
                           class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition duration-150 ease-in-out
                                  {{ request()->routeIs('admin.roles.*') ? 'bg-white/15 text-white shadow-sm' : 'text-indigo-200 hover:text-white hover:bg-white/10' }}">
                            <svg class="w-4 h-4" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                            </svg>
                            <span>Roles</span>
                        </a>
                        @endif
                    </div>
                </div>
            @endauth
        </div>

        {{-- User section --}}
        <div class="border-t border-white/10 p-4 shrink-0 bg-indigo-900/50">
            @auth
                <div class="flex items-center gap-3">
                    <div class="w-9 h-9 rounded-full bg-gradient-to-br from-indigo-400 to-purple-500 flex items-center justify-center text-white text-sm font-bold shrink-0 shadow-md">
                        {{ strtoupper(substr(Auth::user()->name, 0, 1)) }}
                    </div>
                    <div class="flex-1 min-w-0">
                        <p class="text-sm font-semibold text-white truncate">{{ Auth::user()->name }}</p>
                        <p class="text-xs text-indigo-200 truncate">{{ auth()->user()->getRoleNames()->implode(', ') }}</p>
                    </div>
                    <form method="POST" action="{{ route('logout') }}">
                        @csrf
                        <button type="submit" class="p-1.5 rounded-lg text-indigo-300 hover:text-white hover:bg-white/10 transition" title="Logout">
                            <svg class="h-5 w-5" stroke="currentColor" fill="none" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                            </svg>
                        </button>
                    </form>
                </div>
            @endauth
        </div>
    </div>
</nav>