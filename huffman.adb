with Ada.Text_IO, Ada.Unchecked_Deallocation, Ada.Assertions;
use Ada.Text_IO, Ada.Assertions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with code, dico, file_priorite;
use code, dico;

package body Huffman is


	type Octet is new Integer range 0 .. 255;
	for Octet'Size use 8; -- permet d'utiliser Octet'Input et Octet'Output,
	                      -- pour lire/ecrire un octet dans un flux

	type Noeud is record
		Lettre: Character;	-- Only the leaves matter...
		FilsG: Arbre;
		FilsD: Arbre;
	end record;

	type Internal_Huffman is record
		dico : Dico_Caracteres;
		nb_char : Integer;
	end record;

	procedure Libere is new Ada.Unchecked_Deallocation (Noeud, Arbre);

	function Est_Vide (A : in Arbre) return Boolean;
	function Est_une_Feuille(A : in Arbre) return Boolean;

	-- Lit un arbre stocke dans un flux ouvert en lecture
	-- Le format de stockage est celui decrit dans le sujet
	procedure Lire_Fichier(Nom_Fichier : in String; D : out Dico_Caracteres;
				N : out Integer);

	procedure Genere_Code(D: in out Dico_Caracteres);

	-- Retourne un dictionnaire contenant les caracteres presents
	-- dans l'arbre et leur code binaire (evite les parcours multiples)
	-- de l'arbre
	--function Genere_Dictionnaire(H : in Arbre_Huffman) return Dico_Caracteres;


-- Parcours a l'aide d'un iterateur sur un code, en partant du noeud A
--  * Si un caractere a ete trouve il est retourne dans Caractere et
--    Caractere_Trouve vaut True. Le code n'a eventuellement pas ete
--    totalement parcouru. A est une feuille.
--  * Si l'iteration est terminee (plus de bits a parcourir ds le code)
--    mais que le parcours s'est arrete avant une feuille, alors
--    Caractere_Trouve vaut False, Caractere est indetermine
--    et A est le dernier noeud atteint.
	procedure Get_Caractere(It_Code : in Iterateur_Code; A : in out Arbre;
				Caractere_Trouve : out Boolean;
				Caractere : out Character);


--------------------------------------------------------------------------------

	function Est_une_Feuille(A : in Arbre) return Boolean is
	begin
		return A.FilsG = null and then A.FilsD = null;
	end Est_une_Feuille;

	function Est_Vide (A : in Arbre) return Boolean is
	begin
		return A = null;
	end Est_Vide;



	procedure Libere(H : in out Arbre_Huffman) is
	begin
		null;
		--if Est_Vide(H.A) then
			--return;
		--end if;

		--Libere(H.A.FilsD);
		--Libere(H.A.FilsG);

		--Libere(H.A);
		--H.A := null;
	end Libere;

    function To_Unbounded_String(A : Arbre; D : Dico_Caracteres) return Unbounded_string is

		function Aligne(profondeur : Integer) return Unbounded_string;
		function Gauche(A : Arbre; profondeur : Integer) return Unbounded_string;
		function Droit(A : Arbre; profondeur : Integer) return Unbounded_string;
		function Child(A : Arbre; profondeur : Integer) return Unbounded_string;
		function Aligne_Tab(profondeur : Integer) return Unbounded_string;
		function Feuille(A : Arbre; profondeur : Integer) return Unbounded_string;

		function Aligne(profondeur : Integer) return Unbounded_string is
		begin
			if profondeur = 0 then
				return To_Unbounded_String("");
			else
				return "│   " & Aligne(profondeur - 1);
			end if;
		end Aligne;

		function Gauche(A : Arbre; profondeur : Integer) return Unbounded_string is
			str : Unbounded_string := Null_Unbounded_String;
		begin
			Append(str, "┬─0─");
			Append(str, Child(A, profondeur));
			return str;
		end Gauche;

		function Droit(A : Arbre; profondeur : Integer) return Unbounded_string is
			str : Unbounded_string := Null_Unbounded_String;
		begin
			Append(str, "└─1─");
			Append(str, Child(A, profondeur));
			return str;
		end Droit;

		 function Child(A : Arbre; profondeur : Integer) return Unbounded_string is
			str : Unbounded_string := Null_Unbounded_String;
		begin
			if Est_une_Feuille(A) then
				return Feuille(A, profondeur);
			else
				Append(str, Gauche(A.FilsG, profondeur + 1));
				Append(str, Aligne(profondeur));
				Append(str, Droit(A.FilsD, profondeur + 1));
			end if;
			return str;
		end Child;

		function Aligne_Tab(profondeur : Integer) return Unbounded_string is
			str : Unbounded_string := Null_Unbounded_String;
		begin
			if profondeur < 10 then
				Append(str, "    ");
				Append(str, Aligne_Tab(profondeur + 1));
			else
				str := To_Unbounded_String("");
			end if;
			return str;
		end Aligne_Tab;

		function Feuille(A : Arbre; profondeur : Integer) return Unbounded_string is
			str : Unbounded_string := Null_Unbounded_String;
		begin
			Append(str, Aligne_Tab(profondeur));
			case A.Lettre is
				when ASCII.HT =>
					Append(str, "\t");
				when ASCII.LF =>
					Append(str, "\n");
				when others =>
					Append(str, A.Lettre);
			end case;
			Append(str, ": ");
			Append(str, To_Unbounded_String(Get_Code(A.Lettre, D)));
			Append(str, " (");
			Append(str, Integer'Image(Get_Occurrence(D, A.Lettre)));
			Append(str, " occurrences)");
			Append(str, ASCII.LF);
			return str;
		end Feuille;
	begin
        Put_Line("~ Affichage de l'abre de Huffman ~");
		return Child(A, 0);
	end To_Unbounded_String;

	procedure Affiche(H : in Arbre_Huffman) is
	begin
		--Put_Line(To_Unbounded_String(A));
		null;
	end Affiche;

	procedure Lire_Fichier(Nom_Fichier : in String; D : out Dico_Caracteres;
				N : out Integer) is
		Fichier : Ada.Streams.Stream_IO.File_Type;
		Flux : Ada.Streams.Stream_IO.Stream_Access;
		C: Character;
	begin
		D := Cree_Dico;
		Open(Fichier, In_File, Nom_Fichier);
		Flux := Stream(Fichier);
		N := 0;

		New_Line;
		Put_Line("~Lecture en cours du fichier " & nom_fichier & " ~");

		Assert( not End_Of_File(Fichier), "Le fichier " & nom_fichier & " semble vide");

		-- lecture tant qu'il reste des caracteres
		while not End_Of_File(Fichier) loop
			C := Character'Val(Octet'Input(Flux));

			-- Pour le debug, à supprimer ensuite
			Put(C);

			New_Occurrence(D, C);
			N := N + 1;
		end loop;
		Close(Fichier);
	end Lire_Fichier;

	procedure Genere_Code(D: in out Dico_Caracteres) is
		package Priority_Queue is new File_Priorite(
			Arbre,
			Integer,
			"<");
		use Priority_Queue;

		queue_arbre : constant File_Prio := Cree_File(256); -- Il faudrait utiliser un attribut tel que dico'last mais je ne sais pas comment l'utiliser
		fg, fd, A : Arbre;
		prio_g, prio_d : Integer;
		nb_occur : Natural;
	begin
		Put_Line("~Initialisation de la file de priorite~");

		-- On ajoute dans la file de priorite les futures feuille de l'arbre de huffman
		-- Ce sont tous les caractères ayant au moins une occurence
		for it_dico in Character'Range loop
			nb_occur := Get_Occurrence(D, it_dico);
			if nb_occur > 0 then
				Insere(queue_arbre,
					   new Noeud'(it_dico,
								   null,
								   null),
					   nb_occur);
			end if;
		end loop;

		-- On regroupe les deux noeuds de plus faible valeure et ainsi de suite
		-- jusqu'à ce qu'on n'ai plus qu'un arbre unique
		loop
			Supprime(queue_arbre, fg, prio_g);
			exit when Est_Vide(queue_arbre);
			Supprime(queue_arbre, fd, prio_d);
			Insere(queue_arbre,
					new Noeud'( fg.Lettre, fg, fd),
					prio_g + prio_d);
			--Put (Integer'Image(prio_g + prio_d));
			--Put (fg.Lettre);
			--Put (fd.Lettre);
			--new_Line;
		end loop;
		-- À ce point la, l'Arbre de huffman est le fils gauche
		A := fg;
		Put_Line(To_String(To_Unbounded_String(A, D)));
		new_Line;

		Put_Line("~Initialistation de l'arbre de Huffman~");
		-- On génère les codes à partir de l'arbre de huffman
		declare
			procedure Internal_Genere_Code(A: in Arbre; C : in Code_Binaire;
										   D: in out Dico_Caracteres) is
				Code_FG, Code_FD : Code_Binaire;
			begin
				if Est_une_Feuille(A) then
					Set_Code(A.Lettre, C, D);
				else
					-- On fait une copie du Code_Binaire dans l'arbre gauche
					-- L'arbre droit peut en revanche modifier le Code_Binaire
					-- vu que ce code ne sera plus jamais utilisé ailleurs
					Code_FG := C;
					Code_FD := Cree_Code(C);

					Ajoute_Avant(ZERO, Code_FG);
					Ajoute_Avant(UN, Code_FD);

					Internal_Genere_Code(A.FilsG, Code_FG, D);
					Internal_Genere_Code(A.FilsD, Code_FD, D);
				end if;
			end Internal_Genere_Code;

		begin
			Internal_Genere_Code(A, Cree_Code, D);
		end;

		Affiche(D);
	end Genere_Code;

	-- Cree un arbre de Huffman a partir d'un fichier texte
	-- Cette function lit le fichier et compte le nb d'occurences des
	-- differents caracteres presents, puis genere l'arbre correspondant
	-- et le retourne.
	function Cree_Huffman(Nom_Fichier : in String) return Arbre_Huffman is

		D: Dico_Caracteres;
		N: Integer;

		H: Arbre_Huffman;
	begin
		Lire_Fichier(Nom_Fichier, D, N);
		Genere_Code(D);

		H := new Internal_Huffman'(dico => D, nb_char => N);

        return H;
	end Cree_Huffman;

	-- Stocke un arbre dans un flux ouvert en ecriture
	-- Le format de stockage est celui decrit dans le sujet
	-- Retourne le nb d'octets ecrits dans le flux (pour les stats)
	function Ecrit_Huffman(H : in Arbre_Huffman; stream : Stream_Access) return Natural is
		Fichier : Ada.Streams.Stream_IO.File_Type;
		NbOctets: constant Natural := 0;
		O: Octet;
        Nom_Fichier : String := ""; -- fix
	begin
		Create(Fichier, Out_File, Nom_Fichier);
		--stream := Stream(Fichier);

		Put("~Ecriture en cours~");

		--Integer'Output(stream, I1);
		Octet'Output(stream, O);
		Character'Output(stream, 'a');
		Character'Output(stream, 'b');
		Character'Output(stream, 'c');

		Close(Fichier);

		return NbOctets;
	end Ecrit_Huffman;


------ Parcours de l'arbre (decodage)

-- Parcours a l'aide d'un iterateur sur un code, en partant du noeud A
--  * Si un caractere a ete trouve il est retourne dans Caractere et
--    Caractere_Trouve vaut True. Le code n'a eventuellement pas ete
--    totalement parcouru. A est une feuille.
--  * Si l'iteration est terminee (plus de bits a parcourir ds le code)
--    mais que le parcours s'est arrete avant une feuille, alors
--    Caractere_Trouve vaut False, Caractere est indetermine
--    et A est le dernier noeud atteint.
	procedure Get_Caractere(It_Code : in Iterateur_Code; A : in out Arbre; Caractere_Trouve : out Boolean; Caractere : out Character) is

	begin
        null;
	end Get_Caractere;

end Huffman;
