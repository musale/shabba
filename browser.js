function getUrls() {
    const urls = []
    const titles = document.getElementsByClassName("title style-scope ytmusic-responsive-list-item-renderer complex-string")
    for (let t of titles){
        if (t.firstElementChild){
        const url = new URL(t.firstElementChild.href)
        const songID = url.searchParams.get("v")
        const songURL = `${url.origin}${url.pathname}?v=${songID}`
        urls.push({title: t.title, url: songURL})
        }
    }
    return urls
}

async function saveFile(content){
    const handle = await window.showSaveFilePicker()
    const ws = await handle.createWritable()
    await ws.write(JSON.stringify(content))
    await ws.close()
}

// just call this function in the console
saveFile(getUrls()).then(f=>console.log("done")).catch(err=>console.error(err))