local PlayerData = {}

export type PetSize = "Baby" | "Teenager" | "Adult" | "Elder"

export type PetRarity = "Noob" | "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythical"

export type PetAura = "Normal" | "Gold" | "Platinum" | "Diamond" | "Cosmic"

export type BoostType = "Luck" | "Production" | "DoubleMoney" | "AutoCollect"

export type PetData = {
    id: string,
    name: string,
    boostType: BoostType,
    boostAmount: number,
    size: PetSize,
    rarity: PetRarity,
    aura: PetAura,
    dateAcquired: number,
}

export type Boost = {
    id: string,
    name: string,
    description: string,
    boostType: BoostType,
    boostAmount: number,
    endsAtTimeStamp: number,
}

export type PlayerResources = {
    money: number,
    rebirths: number,
    diamonds: number,
}

export type PlayerData = {
    resources: PlayerResources,
    boughtPlots: {number},
    ownedPets: {PetData},
    companionPets: {PetData},
    activeBoosts: {Boost},
    settings: {
        musicEnabled: boolean,
        sfxEnabled: boolean,
    },
    stats: {
        playtime: number,
        joins: number,
        totalPetsCollected: number,
        totalRebirths: number,
    }
}

return PlayerData