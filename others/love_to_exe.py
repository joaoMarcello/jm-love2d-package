import shutil
import os
from glob import glob

path_to_game = "WIRES - copy"
path_temp = path_to_game + " temp/"
ignore = ["icon", "screenshots"]

if not os.path.exists(path_temp):
    os.makedirs(path_temp)


def get_extension(str):
    index = 1
    found = False
    for i, c in enumerate(str):
        if str[i] == ".":
            index = i
            found = True
            break
    if found:
        return str[(-len(str)+index):]
    return False


def to_ignore(str):
    for value in ignore:
        dir = str[len(path_to_game) + 1:][:len(value)]
        print(dir)
        if dir == value:
            return True
    return False


def create_dirs_in_temp(files_in_dir):
    for file in files_in_dir:
        ext = get_extension(file)
        if ext != ".aseprite" and ext != ".clip" and ext != ".git" and ext != ".vscode" and ext != ".love":
            try:
                shutil.copy(file, path_temp + file[len(path_to_game):])
            except:
                try:
                    dir = path_temp + "/" + file[len(path_to_game):]
                    if not os.path.exists(dir):
                        os.makedirs(dir)
                except:
                    b = 1
                a = 1


def remove_love_files():
    try:
        os.remove("love-11.4-win32/game.love")
    except:
        print(">> error removing love-11.4-win32/game.love")

    try:
        os.remove("love-11.4-win64/game.love")
    except:
        print(">> error removing love-11.4-win64/game.love")

    try:
        os.remove("game.love")
    except:
        print(">> error removing game.love")


def create_and_copy_game_love():
    shutil.make_archive('game', 'zip', path_temp)
    os.rename('game.zip', 'game.love')
    shutil.copy('game.love', 'love-11.4-win64')
    shutil.move('game.love', 'love-11.4-win32')


def create_exe(path):
    os.chdir(path)
    os.system('copy /b love.exe+game.love supergame.exe')
    os.remove('game.love')
    #
    files_love = glob("*.*")
    # print(files_love)
    save_exe = 'temp'
    if not os.path.exists(save_exe):
        os.makedirs(save_exe)
    for file in files_love:
        if file != "love.exe" and file != "love.ico" and file != "lovec.exe":
            shutil.copy(file, save_exe)
    os.remove('supergame.exe')


def finish():
    try:
        shutil.rmtree('temp')
    except:
        a = 1
    shutil.move('love-11.4-win32/temp', './')

    try:
        shutil.rmtree(path_to_game + '-win32')
    except:
        b = 1
    os.rename('temp', path_to_game + '-win32')

    shutil.move('love-11.4-win64/temp', './')
    try:
        shutil.rmtree(path_to_game + '-win64')
    except:
        a = 1
    os.rename('temp', path_to_game + '-win64')


files_in_dir = glob(pathname=path_to_game + '/**', recursive=True)
create_dirs_in_temp(files_in_dir)
remove_love_files()
create_and_copy_game_love()

last_cwd = os.getcwd()
create_exe("love-11.4-win32")
create_exe(last_cwd + "/love-11.4-win64")

os.chdir(last_cwd)
finish()

if not os.path.exists("- build exe"):
    os.makedirs("- build exe")

try:
    shutil.rmtree("- build exe/" + path_to_game + "-win32")
except:
    a = 1
try:
    shutil.rmtree("- build exe/" + path_to_game + "-win64")
except:
    b = 1

shutil.move(path_to_game + "-win32", "- build exe")
shutil.move(path_to_game + "-win64", "- build exe")

# Erasing temp folder
os.chdir(last_cwd)
# shutil.rmtree(path_temp)
