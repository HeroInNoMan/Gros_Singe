-- Script de création des tables liées au Gros_Singe

DROP TABLE IF EXISTS taquets, patterns;
CREATE TABLE taquets(key, text, output);
CREATE TABLE patterns(key, pattern);
DROP TABLE IF EXISTS citations;
CREATE TABLE citations(key, text);
