<?php

return [
    'timezone' => env(
        'ATTENDANCE_TIMEZONE',
        'Asia/Jakarta'
    ),

    'check_in_reminder' => env(
        'ATTENDANCE_CHECK_IN_REMINDER',
        '08:45'
    ),

    'check_out_reminder' => env(
        'ATTENDANCE_CHECK_OUT_REMINDER',
        '17:00'
    ),

    'work_days' => array_map(
        'intval',
        explode(
            ',',
            env(
                'ATTENDANCE_WORK_DAYS',
                '1,2,3,4,5'
            )
        )
    ),
];
