#include <assert.h>

#include "imgui.h"
#include "TextEditor.h"

extern "C" {
  TextEditor* imgui_text_editor_init();
  void imgui_text_editor_deinit(TextEditor*);
  void imgui_text_editor_set_text(TextEditor*, const char*);
  int imgui_text_editor_get_total_lines(TextEditor* text_editor);
  void imgui_text_editor_render(TextEditor*, const char*, const ImVec2);
}

TextEditor* imgui_text_editor_init() {
  static TextEditor editor;
  auto lang = TextEditor::LanguageDefinition::C();
	// set your own known preprocessor symbols...
	static const char* ppnames[] = { "add" };
	// ... and their corresponding values
	static const char* ppvalues[] = { 
		"add instruction", 
  };

	for (int i = 0; i < sizeof(ppnames) / sizeof(ppnames[0]); ++i)
	{
		TextEditor::Identifier id;
		id.mDeclaration = ppvalues[i];
		lang.mPreprocIdentifiers.insert(std::make_pair(std::string(ppnames[i]), id));
	}

	// set your own identifiers
	static const char* identifiers[] = {
    "adc",
    "add",
    "and",
    "b",
    "bic",
    "bkpt",
    "bl",
    "blx",
    "bx",
    "bxj",
    "cdp",
    "cdp2",
    "clz",
    "cmn",
    "cmp",
    "eor",
    "ldc",
    "ldc2",
    "ldm",
    "ldr",
    "ldrb",
    "ldrd",
    "ldrbt",
    "ldrh",
    "ldrsb",
    "ldrsh",
    "ldrt",
    "mcr",
    "mcr2",
    "mcrr",
    "mla",
    "mov",
    "mrc",
    "mrc2",
    "mrrc",
    "mrs",
    "msr",
    "mul",
    "mvn",
    "orr",
    "pld",
    "qadd",
    "qdadd",
    "qdsub",
    "qsub",
    "rsb",
    "rsc",
    "sbc",
    "smlal",
    "smlabb",
    "smlabt",
    "smlatb",
    "smlatt",
    "smlalbb",
    "smlalbt",
    "smlaltb",
    "smlaltt",
    "smlawb",
    "smlawt",
    "smulbb",
    "smulbt",
    "smultb",
    "smultt",
    "smull",
    "smulwb",
    "smulwt",
    "stc",
    "stc2",
    "stm",
    "str",
    "strb",
    "strbt",
    "strd",
    "strh",
    "strt",
    "sub",
    "svc",
    "swi",
    "swp",
    "swpb",
    "teq",
    "tst",
    "umlal",
    "umull",
  };
	for (int i = 0; i < sizeof(identifiers) / sizeof(identifiers[0]); ++i)
	{
		TextEditor::Identifier id;
		// id.mDeclaration = std::string(idecls[i]);
		lang.mIdentifiers.insert(std::make_pair(std::string(identifiers[i]), id));
	}
  editor.SetLanguageDefinition(lang);
  editor.SetShowWhitespaces(false);
  return &editor;
}

void imgui_text_editor_set_text(TextEditor* editor, const char* text) {
  editor->SetText(text);
  // editor->InsertText(text);
}

void imgui_text_editor_deinit(TextEditor* text_editor) {
  text_editor = NULL;
}
void imgui_text_editor_render(TextEditor* text_editor, const char* id, const ImVec2 aSize) {
  text_editor->Render(id);
}

int imgui_text_editor_get_total_lines(TextEditor* text_editor) {
  return text_editor->GetTotalLines();
}
