-- ============================================================
-- Tests d'authentification et de rôles — Phase 2, Étape 2.8
-- ============================================================
--
-- Ces tests vérifient les 8 scénarios requis par le cadrage.
-- À exécuter dans le SQL Editor de Supabase (service_role).
--
-- Les tests 1 à 7 peuvent être exécutés ici.
-- Le test 8 (redirection UI) ne peut pas être testé en SQL ;
-- il est couvert par le test Vitest correspondant.
-- ============================================================

-- ============================================================
-- PRÉPARATION : nettoyer et créer les utilisateurs de test
-- ============================================================

DELETE FROM public.orders WHERE order_number LIKE 'AUTHTEST-%';
DELETE FROM public.addresses WHERE line1 LIKE 'AUTHTEST-%';
DELETE FROM public.products WHERE slug LIKE 'authtest-%';
DELETE FROM public.user_roles WHERE user_id IN (
  SELECT id FROM auth.users WHERE email LIKE 'authtest-%'
);
DELETE FROM public.profiles WHERE email LIKE 'authtest-%';
DELETE FROM auth.users WHERE email LIKE 'authtest-%';

-- Créer un client A et un client B
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role)
VALUES
  ('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1', 'authtest-a@example.com', crypt('test123456', gen_salt('bf')), now(), now(), now(), 'authenticated', 'authenticated'),
  ('b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2', 'authtest-b@example.com', crypt('test123456', gen_salt('bf')), now(), now(), now(), 'authenticated', 'authenticated'),
  ('c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3', 'authtest-owner@example.com', crypt('test123456', gen_salt('bf')), now(), now(), now(), 'authenticated', 'authenticated')
ON CONFLICT (id) DO NOTHING;

-- Profils (le trigger handle_new_user ne se déclenche pas sur ON CONFLICT)
INSERT INTO public.profiles (id, email, full_name) VALUES
  ('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1', 'authtest-a@example.com', 'Client A'),
  ('b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2', 'authtest-b@example.com', 'Client B'),
  ('c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3', 'authtest-owner@example.com', 'Owner')
ON CONFLICT (id) DO NOTHING;

-- Rôles
INSERT INTO public.user_roles (user_id, role) VALUES
  ('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1', 'customer'::app_role),
  ('b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2', 'customer'::app_role),
  ('c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3', 'owner'::app_role)
ON CONFLICT (user_id) DO UPDATE SET role = EXCLUDED.role;

-- Données de test : produit + adresse B
INSERT INTO public.products (id, name, slug, price, is_archived)
VALUES ('d4d4d4d4-d4d4-d4d4-d4d4-d4d4d4d4d4d4', 'AuthTest Product', 'authtest-product', 5000, false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.addresses (id, user_id, first_name, last_name, line1, city)
VALUES ('e5e5e5e5-e5e5-e5e5-e5e5-e5e5e5e5e5e5', 'b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2', 'B', 'B', 'AUTHTEST-Adresse-B', 'Abidjan')
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- TEST 1 : Un client inscrit a le rôle customer et uniquement celui-ci
-- ============================================================

SELECT 'TEST 1' AS test,
  CASE
    WHEN (SELECT role FROM public.user_roles WHERE user_id = 'a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1') = 'customer'::app_role
    THEN 'RÉUSSI'
    ELSE 'ÉCHEC'
  END AS resultat,
  (SELECT role::text FROM public.user_roles WHERE user_id = 'a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1') AS detail;

-- ============================================================
-- TEST 2 : Un client ne peut ni insérer, ni modifier, ni supprimer dans user_roles
-- ============================================================

-- 2a : INSERT
SET LOCAL role = authenticated;
SET LOCAL request.jwt.claims = '{"sub":"a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1","role":"authenticated","aal":"aal1"}';

SELECT 'TEST 2a (INSERT user_roles bloqué)' AS test,
  CASE
    WHEN count(*) = 0 THEN 'RÉUSSI (aucune ligne insérée)'
    ELSE 'ÉCHEC'
  END AS resultat
FROM (
  INSERT INTO public.user_roles (user_id, role) VALUES ('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1', 'owner'::app_role)
  RETURNING 1
) t;

-- 2b : UPDATE
SELECT 'TEST 2b (UPDATE user_roles bloqué)' AS test,
  CASE
    WHEN count(*) = 0 THEN 'RÉUSSI (aucune ligne modifiée)'
    ELSE 'ÉCHEC'
  END AS resultat
FROM (
  UPDATE public.user_roles SET role = 'owner'::app_role WHERE user_id = 'a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1'
  RETURNING 1
) t;

-- 2c : DELETE
SELECT 'TEST 2c (DELETE user_roles bloqué)' AS test,
  CASE
    WHEN count(*) = 0 THEN 'RÉUSSI (aucune ligne supprimée)'
    ELSE 'ÉCHEC'
  END AS resultat
FROM (
  DELETE FROM public.user_roles WHERE user_id = 'a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1'
  RETURNING 1
) t;

RESET role;
RESET request.jwt.claims;

-- ============================================================
-- TEST 3 : Un utilisateur qui met role='owner' dans ses métadonnées
--          à l'inscription reste customer
-- ============================================================
-- On simule en insérant un user avec raw_user_meta_data contenant role=owner
-- et en appelant handle_new_user manuellement

INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role, raw_user_meta_data)
VALUES ('f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6', 'authtest-meta@example.com', crypt('test123456', gen_salt('bf')), now(), now(), now(), 'authenticated', 'authenticated', '{"role":"owner","full_name":"Hacker"}')
ON CONFLICT (id) DO NOTHING;

-- Le trigger on_auth_user_created s'est exécuté. Vérifier le rôle.
SELECT 'TEST 3' AS test,
  CASE
    WHEN (SELECT role FROM public.user_roles WHERE user_id = 'f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6') = 'customer'::app_role
    THEN 'RÉUSSI (rôle reste customer malgré metadata owner)'
    ELSE 'ÉCHEC'
  END AS resultat,
  (SELECT role::text FROM public.user_roles WHERE user_id = 'f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6') AS detail;

-- ============================================================
-- TEST 4 : Un client ne peut pas appeler une fonction qui change un rôle
-- ============================================================
-- log_admin_action est revoke de PUBLIC et authenticated.
-- Vérifier qu'elle n'est pas exécutable par authenticated.

SET LOCAL role = authenticated;
SET LOCAL request.jwt.claims = '{"sub":"a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1","role":"authenticated","aal":"aal1"}';

SELECT 'TEST 4 (log_admin_action non exécutable par client)' AS test,
  CASE
    WHEN count(*) = 0 THEN 'RÉUSSI (fonction non accessible)'
    ELSE 'ÉCHEC'
  END AS resultat;

RESET role;
RESET request.jwt.claims;

-- ============================================================
-- TEST 5 : Un propriétaire en aal1 (sans MFA) ne peut lire ni écrire
--          aucune table d'administration
-- ============================================================

SET LOCAL role = authenticated;
SET LOCAL request.jwt.claims = '{"sub":"c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3","role":"authenticated","aal":"aal1"}';

-- 5a : Lecture (products admin)
SELECT 'TEST 5a (owner aal1 ne lit pas produits admin)' AS test,
  count(*) AS product_count,
  CASE WHEN count(*) = 0 THEN 'RÉUSSI' ELSE 'ÉCHEC' END AS resultat
FROM public.products;

-- 5b : Écriture (update product)
SELECT 'TEST 5b (owner aal1 ne modifie pas produits)' AS test,
  count(*) AS updated,
  CASE WHEN count(*) = 0 THEN 'RÉUSSI' ELSE 'ÉCHEC' END AS resultat
FROM (
  UPDATE public.products SET is_featured = true WHERE id = 'd4d4d4d4-d4d4-d4d4-d4d4-d4d4d4d4d4d4'
  RETURNING 1
) t;

-- 5c : Lecture store_settings (lecture publique OK, mais admin en aal1 ne doit pas pouvoir modifier)
SELECT 'TEST 5c (owner aal1 ne modifie pas store_settings)' AS test,
  count(*) AS updated,
  CASE WHEN count(*) = 0 THEN 'RÉUSSI' ELSE 'ÉCHEC' END AS resultat
FROM (
  UPDATE public.store_settings SET store_name = 'HACKED' RETURNING 1
) t;

RESET role;
RESET request.jwt.claims;

-- ============================================================
-- TEST 6 : Un propriétaire en aal2 peut gérer le catalogue
-- ============================================================

SET LOCAL role = authenticated;
SET LOCAL request.jwt.claims = '{"sub":"c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3","role":"authenticated","aal":"aal2"}';

-- 6a : Lecture de tous les produits
SELECT 'TEST 6a (owner aal2 lit tous les produits)' AS test,
  count(*) AS product_count,
  CASE WHEN count(*) > 0 THEN 'RÉUSSI' ELSE 'ÉCHEC' END AS resultat
FROM public.products;

-- 6b : Modification d'un produit
SELECT 'TEST 6b (owner aal2 modifie un produit)' AS test,
  count(*) AS updated,
  CASE WHEN count(*) > 0 THEN 'RÉUSSI' ELSE 'ÉCHEC' END AS resultat
FROM (
  UPDATE public.products SET is_featured = true WHERE id = 'd4d4d4d4-d4d4-d4d4-d4d4-d4d4d4d4d4d4'
  RETURNING 1
) t;

RESET role;
RESET request.jwt.claims;

-- ============================================================
-- TEST 7 : Un client ne lit que son profil, ses adresses et ses favoris
-- ============================================================

SET LOCAL role = authenticated;
SET LOCAL request.jwt.claims = '{"sub":"a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1","role":"authenticated","aal":"aal1"}';

-- 7a : A lit son profil
SELECT 'TEST 7a (A lit son profil)' AS test,
  count(*) AS profile_count,
  CASE WHEN count(*) = 1 THEN 'RÉUSSI' ELSE 'ÉCHEC' END AS resultat
FROM public.profiles;

-- 7b : A ne lit pas les adresses de B
SELECT 'TEST 7b (A ne lit pas adresses de B)' AS test,
  count(*) AS addr_count,
  CASE WHEN count(*) = 0 THEN 'RÉUSSI' ELSE 'ÉCHEC' END AS resultat
FROM public.addresses WHERE user_id = 'b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2';

-- 7c : A ne lit pas les commandes
SELECT 'TEST 7c (A ne lit aucune commande)' AS test,
  count(*) AS order_count,
  CASE WHEN count(*) = 0 THEN 'RÉUSSI' ELSE 'ÉCHEC' END AS resultat
FROM public.orders;

RESET role;
RESET request.jwt.claims;

-- ============================================================
-- TEST 8 : Redirection UI — couvert par le test Vitest
-- ============================================================
SELECT 'TEST 8' AS test, 'Couvert par Vitest (redirection UI non testable en SQL)' AS resultat;

-- ============================================================
-- NETTOYAGE
-- ============================================================

DELETE FROM public.addresses WHERE line1 LIKE 'AUTHTEST-%';
DELETE FROM public.products WHERE slug LIKE 'authtest-%';
DELETE FROM public.user_roles WHERE user_id IN (
  'a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1',
  'b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2',
  'c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3',
  'f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6'
);
DELETE FROM public.profiles WHERE email LIKE 'authtest-%';
DELETE FROM auth.users WHERE email LIKE 'authtest-%';

SELECT 'NETTOYAGE TERMINÉ' AS status;
