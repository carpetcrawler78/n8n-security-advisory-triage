-- Synthetic asset inventory: seven installations at three fictional customers.
-- Synthetisches Asset-Inventar: sieben Installationen bei drei erfundenen Kunden.
INSERT INTO public.asset_inventory
    (asset_id, customer_name, device_name, vendor, product, installed_version)
VALUES
    ('A-REM-01', 'Kunde A – Werkzeugbau',              'Fernwartungsserver 1', 'Musterwerk Systems GmbH', 'MusterLink Remote Gateway', '2.3.1'),
    ('A-REM-02', 'Kunde A – Werkzeugbau',              'Fernwartungsserver 2', 'Musterwerk Systems GmbH', 'MusterLink Remote Gateway', '2.3.2'),
    ('A-BKP-01', 'Kunde A – Werkzeugbau',              'Sicherungsserver',     'SicherWerk Software AG',  'DataSafe Backup',           '6.1'),
    ('B-REM-01', 'Kunde B – Verpackungstechnik',       'Fernwartungsserver',   'Musterwerk Systems GmbH', 'MusterLink Remote Gateway', '2.4.0'),
    ('B-HMI-01', 'Kunde B – Verpackungstechnik',       'Produktionsrechner',   'Anlagenblick GmbH',       'PlantView HMI',             '7.4'),
    ('C-REM-01', 'Kunde C – Medizintechnik-Zulieferer', 'Fernwartungsserver',  'Musterwerk Systems GmbH', 'MusterLink Remote Gateway', '2.3.0'),
    ('C-ERP-01', 'Kunde C – Medizintechnik-Zulieferer', 'Verwaltungsserver',   'Warenstrom Software GmbH', 'WarenFlow ERP',            '3.8')
ON CONFLICT (asset_id) DO NOTHING;
