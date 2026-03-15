unit uAssets;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Forms;

type
  TDirection = (dirRight, dirLeft, dirUp, dirDown);

// ---------------------------------------------------------------------------
// TSprite -- every sprite the game uses.
//
// To add a new sprite:
//   1. Add a value here.
//   2. Add the matching filename in SPRITE_FILE (implementation section).
//   The compiler enforces that both arrays stay the same length.
// ---------------------------------------------------------------------------
type
  TSprite = (
    // background
    spBg,
    spBgSick,

    // food
    spApple,
    spPear,

    // head sprites
    spHeadRight,
    spHeadLeft,
    spHeadUp,
    spHeadDown,

    // body sprites
    spBodyH,
    spBodyV,

    // body turning sprites
    spBodyTL,
    spBodyTR,
    spBodyBL,
    spBodyBR,

    // tail sprites
    spTailRight,
    spTailLeft,
    spTailUp,
    spTailDown
  );

// ---------------------------------------------------------------------------
// TAssetManager
//
// Responsibilities:
//   - Locate the assets directory relative to the executable.
//   - Load every PNG sprite into a TBitmap, indexed by TSprite.
//   - Provide a single Get() accessor for callers.
//   - Own all bitmap lifetime (freed in Destroy).
//
// Usage:
//   Assets := TAssetManager.Create;
//   Assets.Load;                        // call once at startup
//   Canvas.Draw(x, y, Assets[spApple]); // array-property access
//   Assets.Free;
// ---------------------------------------------------------------------------
type
  TAssetManager = class
  private
    FSprites : array[TSprite] of TBitmap;

    function  FindAssetsDir: String;
    procedure LoadPng(ASprite: TSprite; const AFileName: String;
                      const AAssetsDir: String);
  public
    destructor Destroy; override;

    // Load all sprites from disk.  Call once after construction.
    procedure Load;

    // Direct indexed access: Assets[spApple]
    function Get(ASprite: TSprite): TBitmap;

    function GetHeadSprite(ADirection: TDirection): TBitmap;
    function GetTailSprite(ADirection: TDirection): TBitmap;

    property Sprites[ASprite: TSprite]: TBitmap read Get; default;
  end;

implementation

// ---------------------------------------------------------------------------
// Filename table -- order must match TSprite exactly (compile-time enforced).
// ---------------------------------------------------------------------------
const
  SPRITE_FILE: array[TSprite] of String = (
    'bg.png',
    'bg_sick.png',
    'apple.png',
    'pear.png',
    'head_right.png',
    'head_left.png',
    'head_up.png',
    'head_down.png',
    'body_h.png',
    'body_v.png',
    'body_tl.png',
    'body_tr.png',
    'body_bl.png',
    'body_br.png',
    'tail_right.png',
    'tail_left.png',
    'tail_up.png',
    'tail_down.png');

// ---------------------------------------------------------------------------
// TAssetManager
// ---------------------------------------------------------------------------

destructor TAssetManager.Destroy;
var
  S: TSprite;
begin
  for S := Low(TSprite) to High(TSprite) do
    FSprites[S].Free;
  inherited;
end;

function TAssetManager.FindAssetsDir: String;
const
  FOLDER = 'assets';
var
  Base : String;
begin
  Base := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));

  // 1. Next to the executable  (shipped layout)
  Result := Base + FOLDER;
  if DirectoryExists(Result) then
    Exit(IncludeTrailingPathDelimiter(Result));

  // 2. Two levels up           (Lazarus IDE: exe in project/lib/cpu-os/)
  Result := ExpandFileName(Base + '../../' + FOLDER);
  if DirectoryExists(Result) then
    Exit(IncludeTrailingPathDelimiter(Result));

  // 3. One level up            (alternative IDE layout)
  Result := ExpandFileName(Base + '../' + FOLDER);
  if DirectoryExists(Result) then
    Exit(IncludeTrailingPathDelimiter(Result));

  raise Exception.CreateFmt(
    'Assets directory "%s" not found near executable:%s%s',
    [FOLDER, LineEnding, Base]);
end;

procedure TAssetManager.LoadPng(ASprite: TSprite; const AFileName: String;
                                const AAssetsDir: String);
var
  PNG  : TPortableNetworkGraphic;
  Path : String;
  BMP  : TBitmap;
begin
  Path := AAssetsDir + AFileName;
  if not FileExists(Path) then
    raise Exception.CreateFmt('Sprite not found: %s', [Path]);

  BMP := TBitmap.Create;
  PNG := TPortableNetworkGraphic.Create;
  try
    PNG.LoadFromFile(Path);
    BMP.Assign(PNG);
    BMP.Transparent     := True;
    BMP.TransparentMode := tmAuto;
  finally
    PNG.Free;
  end;

  FSprites[ASprite] := BMP;
end;

procedure TAssetManager.Load;
var
  S   : TSprite;
  Dir : String;
begin
  Dir := FindAssetsDir;
  for S := Low(TSprite) to High(TSprite) do
    LoadPng(S, SPRITE_FILE[S], Dir);
end;

function TAssetManager.Get(ASprite: TSprite): TBitmap;
begin
  Result := FSprites[ASprite];
  if Result = nil then
    raise Exception.CreateFmt(
      'Sprite %d accessed before TAssetManager.Load was called', [Ord(ASprite)]);
end;

function TAssetManager.GetHeadSprite(ADirection: TDirection): TBitmap;
const
  HEAD_SPRITE: array[TDirection] of TSprite = (
    spHeadRight, spHeadLeft, spHeadUp, spHeadDown);
begin
  Result := Get(HEAD_SPRITE[ADirection]);
end;

function TAssetManager.GetTailSprite(ADirection: TDirection): TBitmap;
const
  TAIL_SPRITE: array[TDirection] of TSprite = (
    spTailRight, spTailLeft, spTailUp, spTailDown);
begin
  Result := Get(TAIL_SPRITE[ADirection]);
end;

end.
