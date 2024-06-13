import std;
import parserino;

// Mappatura pixel tabella -> colonne
// La colonna zero è il beneficiario, non c'è in tabella
static immutable colMap =
[
 	"48px" 	: 1, // Data erogazione
 	"130px" 	: 2, // Anno erogazione
	"189px"	: 3, // Data trasmissione
	"306px"	: 4, // Soggetto erogante
	"568px"	: 5, // N° eroganti
	"627px"	: 6, // Importo
	"767px"	: 7, // Non in denaro
	"857px"	: 8, // Annotazioni
];

void main()
{
	string currentRecipient;

	// Leggo il file HTML creato a partire dal pdf originale
	// pdftohtml -noframes -i -s  ART_5_DL_149_2013_L_3_2019_dal_01012024.pdf data.html
	auto doc = Document("data.html".readText);
	auto rows = doc.bySelector("#page1-div ~ div p");

	stdout.writeln("Beneficiario\tData erogazione\tAnno erogazione\tData trasmissione\tSoggetto erogante\tN°eroganti\tImporto\tNon in denaro\tAnnotazioni");

	while(!rows.empty)
	{
		auto p = rows.front;
		auto isHeader = !p.byTagName("b").empty;

		if (isHeader)
		{
			currentRecipient = p.innerText;
			rows.popFront;
		}
		else
		{
			auto getTop(Element p)
			{
				return
					p.getAttribute("style")	// Attributo style
					.splitter(";")				// Splitto per ;
					.drop(1)						// Tolgo il primo elemento ("position: absolute")
					.front						// Prendo il secondo (top: ...)
					.splitter(":")				// Splitto per :
					.drop(1)						// Tolgo il primo elemento ("top")
					.front;						// Prendo il secondo (il valore di top)
			}

			// Ok siamo dentro una riga di donazione
			// Tutti i campi della riga hanno lo stesso attributo top
			auto currentTop = getTop(p);

			// HACK: se questa è la riga della pagina, la salto
			if (currentTop == "865px" && p.innerText.startsWith("- ") && p.innerText.endsWith(" -"))
			{
				rows.popFront;
				continue;
			}

			string[9] row;
			row[0] = currentRecipient;

			// Le altre colonne
			while(currentTop == getTop(p))
			{
				// Vedi sopra
				auto left = p.getAttribute("style")
					.splitter(";")
					.drop(2)
					.front
					.splitter(":")
					.drop(1)
					.front;

				row[colMap[left]] = p.innerText;

				if (colMap[left] == 6) row[colMap[left]] = row[colMap[left]].split(" ")[1]; // Tolgo il "€ " dall'importo
				rows.popFront;

				if (rows.empty) break;
				else p = rows.front;
			}

			writeln(row[].joiner("\t"));
		}

		if (rows.empty) break;
	}
}
