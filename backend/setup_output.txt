
============================================================
Environment: development
Debug: True
Facilitators Module: ENABLED
Auto Assignment: True
AICerts Sync: True
Socket.io Enabled: True
Socket.io Port: 8001
============================================================

Loading payments admin...
Γ£ô All models registered with correct fields
Γ£ô Payments admin loaded successfully

============================================================
STEP 1: Fix User Account
============================================================
  Found user ID=121: 'Rechard Masukume' (rechard.masukume@hosiacademy.co.za)
  Country: Kenya (ID=28)
  State: Nairobi (ID=138)
  City: Nairobi
  Γ£à User saved: Richard Masukume (role_id=3)

============================================================
STEP 2: Select AICerts Course
============================================================
  Γ£à Course: AI+ ExecutiveΓäó (ID=43, ext=294)
     Price: N/A

============================================================
STEP 3: Setup Kenya Payment Provider
============================================================
  Found Mock provider (ID=10)
  Found Kenya config
  Created M-Pesa method

============================================================
STEP 4: Create Order & Mock M-Pesa Payment
============================================================
  Γ£à Order: HOSI-KE-20260219-A5481DE7 (KES 46494.50)

Γ¥î ERROR: null value in column "company_address" of relation "payment_transactions" violates not-null constraint
DETAIL:  Failing row contains (3, 46494.50, KES, purchase, mock, MOCK-MPESA-0DCFB3EF9759, mobile_money, M-Pesa sandbox payment for: AI+ ExecutiveΓäó, successful, {"sandbox": true, "mpesa_phone": "+254712345678", "course_title"..., t, 2026-02-19 10:02:41.963727+00, t, 2026-02-19, 41.89.228.100, Mozilla/5.0 (Linux; Android 13) Mobile, null, null, KE, +254712345678, 2026-02-19 10:02:41.964511+00, 2026-02-19 10:02:41.964549+00, 2026-02-19 10:02:41.963727+00, 121, 103, 121, 35, null, null, null, null, null, null, null, null, null, null).

venv\Scripts\python : Traceback (most 
recent call last):
At line:1 char:32
+ ... NG='utf-8'; venv\Scripts\python 
setup_richard_masukume.py 2>&1 | Out- ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecifi 
   ed: (Traceback (most recent call las  
  t)::String) [], RemoteException
    + FullyQualifiedErrorId : NativeComm 
   andError
 
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\ba
ckends\utils.py", line 89, in _execute
    return self.cursor.execute(sql, 
params)
           
~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^
psycopg2.errors.NotNullViolation: null 
value in column "company_address" of 
relation "payment_transactions" violates 
not-null constraint
DETAIL:  Failing row contains (3, 
46494.50, KES, purchase, mock, 
MOCK-MPESA-0DCFB3EF9759, mobile_money, 
M-Pesa sandbox payment for: AI+ 
ExecutiveΓäó, successful, {"sandbox": 
true, "mpesa_phone": "+254712345678", 
"course_title"..., t, 2026-02-19 
10:02:41.963727+00, t, 2026-02-19, 
41.89.228.100, Mozilla/5.0 (Linux; 
Android 13) Mobile, null, null, KE, 
+254712345678, 2026-02-19 
10:02:41.964511+00, 2026-02-19 
10:02:41.964549+00, 2026-02-19 
10:02:41.963727+00, 121, 103, 121, 35, 
null, null, null, null, null, null, 
null, null, null, null).


The above exception was the direct cause 
of the following exception:

Traceback (most recent call last):
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\setup_richard_masukume.py", line 
213, in main
    payment = 
PaymentTransaction.objects.create(
        user=user,
    ...<26 lines>...
        provider_config=kenya_config,
    )
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\manager.py", line 87, in 
manager_method
    return getattr(self.get_queryset(), 
name)(*args, **kwargs)
           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~^^^^^^^^^^^^^^^^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\query.py", line 658, in create
    obj.save(force_insert=True, 
using=self.db)
    ~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\base.py", line 814, in save
    self.save_base(
    ~~~~~~~~~~~~~~^
        using=using,
        ^^^^^^^^^^^^
    ...<2 lines>...
        update_fields=update_fields,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    )
    ^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\base.py", line 877, in save_base
    updated = self._save_table(
        raw,
    ...<4 lines>...
        update_fields,
    )
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\base.py", line 1020, in _save_table
    results = self._do_insert(
        cls._base_manager, using, 
fields, returning_fields, raw
    )
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\base.py", line 1061, in _do_insert
    return manager._insert(
           ~~~~~~~~~~~~~~~^
        [self],
        ^^^^^^^
    ...<3 lines>...
        raw=raw,
        ^^^^^^^^
    )
    ^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\manager.py", line 87, in 
manager_method
    return getattr(self.get_queryset(), 
name)(*args, **kwargs)
           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~^^^^^^^^^^^^^^^^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\query.py", line 1805, in _insert
    return query.get_compiler(using=using
).execute_sql(returning_fields)
           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\sql\compiler.py", line 1822, in 
execute_sql
    cursor.execute(sql, params)
    ~~~~~~~~~~~~~~^^^^^^^^^^^^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\ba
ckends\utils.py", line 102, in execute
    return super().execute(sql, params)
           ~~~~~~~~~~~~~~~^^^^^^^^^^^^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\ba
ckends\utils.py", line 67, in execute
    return self._execute_with_wrappers(
           ~~~~~~~~~~~~~~~~~~~~~~~~~~~^
        sql, params, many=False, 
executor=self._execute
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^
    )
    ^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\ba
ckends\utils.py", line 80, in 
_execute_with_wrappers
    return executor(sql, params, many, 
context)
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\ba
ckends\utils.py", line 84, in _execute
    with self.db.wrap_database_errors:
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\ut
ils.py", line 91, in __exit__
    raise 
dj_exc_value.with_traceback(traceback) 
from exc_value
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\ba
ckends\utils.py", line 89, in _execute
    return self.cursor.execute(sql, 
params)
           
~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^
django.db.utils.IntegrityError: null 
value in column "company_address" of 
relation "payment_transactions" violates 
not-null constraint
DETAIL:  Failing row contains (3, 
46494.50, KES, purchase, mock, 
MOCK-MPESA-0DCFB3EF9759, mobile_money, 
M-Pesa sandbox payment for: AI+ 
ExecutiveΓäó, successful, {"sandbox": 
true, "mpesa_phone": "+254712345678", 
"course_title"..., t, 2026-02-19 
10:02:41.963727+00, t, 2026-02-19, 
41.89.228.100, Mozilla/5.0 (Linux; 
Android 13) Mobile, null, null, KE, 
+254712345678, 2026-02-19 
10:02:41.964511+00, 2026-02-19 
10:02:41.964549+00, 2026-02-19 
10:02:41.963727+00, 121, 103, 121, 35, 
null, null, null, null, null, null, 
null, null, null, null).

Traceback (most recent call last):
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\ba
ckends\utils.py", line 89, in _execute
    return self.cursor.execute(sql, 
params)
           
~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^
psycopg2.errors.NotNullViolation: null 
value in column "company_address" of 
relation "payment_transactions" violates 
not-null constraint
DETAIL:  Failing row contains (3, 
46494.50, KES, purchase, mock, 
MOCK-MPESA-0DCFB3EF9759, mobile_money, 
M-Pesa sandbox payment for: AI+ 
ExecutiveΓäó, successful, {"sandbox": 
true, "mpesa_phone": "+254712345678", 
"course_title"..., t, 2026-02-19 
10:02:41.963727+00, t, 2026-02-19, 
41.89.228.100, Mozilla/5.0 (Linux; 
Android 13) Mobile, null, null, KE, 
+254712345678, 2026-02-19 
10:02:41.964511+00, 2026-02-19 
10:02:41.964549+00, 2026-02-19 
10:02:41.963727+00, 121, 103, 121, 35, 
null, null, null, null, null, null, 
null, null, null, null).


The above exception was the direct cause 
of the following exception:

Traceback (most recent call last):
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\setup_richard_masukume.py", line 
316, in <module>
    main()
    ~~~~^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\setup_richard_masukume.py", line 
213, in main
    payment = 
PaymentTransaction.objects.create(
        user=user,
    ...<26 lines>...
        provider_config=kenya_config,
    )
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\manager.py", line 87, in 
manager_method
    return getattr(self.get_queryset(), 
name)(*args, **kwargs)
           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~^^^^^^^^^^^^^^^^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\query.py", line 658, in create
    obj.save(force_insert=True, 
using=self.db)
    ~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\base.py", line 814, in save
    self.save_base(
    ~~~~~~~~~~~~~~^
        using=using,
        ^^^^^^^^^^^^
    ...<2 lines>...
        update_fields=update_fields,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    )
    ^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\base.py", line 877, in save_base
    updated = self._save_table(
        raw,
    ...<4 lines>...
        update_fields,
    )
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\base.py", line 1020, in _save_table
    results = self._do_insert(
        cls._base_manager, using, 
fields, returning_fields, raw
    )
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\base.py", line 1061, in _do_insert
    return manager._insert(
           ~~~~~~~~~~~~~~~^
        [self],
        ^^^^^^^
    ...<3 lines>...
        raw=raw,
        ^^^^^^^^
    )
    ^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\manager.py", line 87, in 
manager_method
    return getattr(self.get_queryset(), 
name)(*args, **kwargs)
           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~^^^^^^^^^^^^^^^^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\query.py", line 1805, in _insert
    return query.get_compiler(using=using
).execute_sql(returning_fields)
           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\mo
dels\sql\compiler.py", line 1822, in 
execute_sql
    cursor.execute(sql, params)
    ~~~~~~~~~~~~~~^^^^^^^^^^^^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\ba
ckends\utils.py", line 102, in execute
    return super().execute(sql, params)
           ~~~~~~~~~~~~~~~^^^^^^^^^^^^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\ba
ckends\utils.py", line 67, in execute
    return self._execute_with_wrappers(
           ~~~~~~~~~~~~~~~~~~~~~~~~~~~^
        sql, params, many=False, 
executor=self._execute
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^
    )
    ^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\ba
ckends\utils.py", line 80, in 
_execute_with_wrappers
    return executor(sql, params, many, 
context)
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\ba
ckends\utils.py", line 84, in _execute
    with self.db.wrap_database_errors:
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\ut
ils.py", line 91, in __exit__
    raise 
dj_exc_value.with_traceback(traceback) 
from exc_value
  File "C:\Users\HosiTech\lms-monorepo\ba
ckend\venv\Lib\site-packages\django\db\ba
ckends\utils.py", line 89, in _execute
    return self.cursor.execute(sql, 
params)
           
~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^
django.db.utils.IntegrityError: null 
value in column "company_address" of 
relation "payment_transactions" violates 
not-null constraint
DETAIL:  Failing row contains (3, 
46494.50, KES, purchase, mock, 
MOCK-MPESA-0DCFB3EF9759, mobile_money, 
M-Pesa sandbox payment for: AI+ 
ExecutiveΓäó, successful, {"sandbox": 
true, "mpesa_phone": "+254712345678", 
"course_title"..., t, 2026-02-19 
10:02:41.963727+00, t, 2026-02-19, 
41.89.228.100, Mozilla/5.0 (Linux; 
Android 13) Mobile, null, null, KE, 
+254712345678, 2026-02-19 
10:02:41.964511+00, 2026-02-19 
10:02:41.964549+00, 2026-02-19 
10:02:41.963727+00, 121, 103, 121, 35, 
null, null, null, null, null, null, 
null, null, null, null).

