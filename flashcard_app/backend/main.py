from typing import List, Optional

from fastapi import Depends, FastAPI, HTTPException
from sqlmodel import Field, Relationship, Session, SQLModel, create_engine, select

# Database Models
class Deck(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    cards: List["Card"] = Relationship(back_populates="deck")

class Card(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    front: str
    back: str
    mastery_level: int = Field(default=0)
    deck_id: Optional[int] = Field(default=None, foreign_key="deck.id")
    deck: Optional[Deck] = Relationship(back_populates="cards")

# API Models (Data Transfer Objects)
class CardRead(SQLModel):
    id: int
    front: str
    back: str
    mastery_level: int
    deck_id: int

class DeckRead(SQLModel):
    id: int
    name: str

class DeckReadWithCards(DeckRead):
    cards: List[CardRead] = []

class CardCreate(SQLModel):
    front: str
    back: str
    deck_id: int

class DeckCreate(SQLModel):
    name: str

class CardUpdate(SQLModel):
    mastery_level: Optional[int] = None

# Database Setup
sqlite_file_name = "database.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"
engine = create_engine(sqlite_url, echo=True)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session

from fastapi.middleware.cors import CORSMiddleware

# FastAPI App
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

@app.on_event("startup")
def on_startup():
    create_db_and_tables()

# API Endpoints
@app.post("/decks", response_model=DeckRead)
def create_deck(deck: DeckCreate, session: Session = Depends(get_session)):
    db_deck = Deck.from_orm(deck)
    session.add(db_deck)
    session.commit()
    session.refresh(db_deck)
    return db_deck

@app.get("/decks", response_model=List[DeckReadWithCards])
def read_decks(session: Session = Depends(get_session)):
    decks = session.exec(select(Deck)).all()
    return decks

@app.post("/cards", response_model=CardRead)
def create_card(card: CardCreate, session: Session = Depends(get_session)):
    db_card = Card.from_orm(card)
    # Verify deck exists
    deck = session.get(Deck, db_card.deck_id)
    if not deck:
        raise HTTPException(status_code=404, detail="Deck not found")
    session.add(db_card)
    session.commit()
    session.refresh(db_card)
    return db_card

@app.get("/decks/{deck_id}/cards", response_model=List[CardRead])
def read_deck_cards(deck_id: int, session: Session = Depends(get_session)):
    deck = session.get(Deck, deck_id)
    if not deck:
        raise HTTPException(status_code=404, detail="Deck not found")
    return deck.cards

@app.patch("/cards/{card_id}", response_model=CardRead)
def update_card(card_id: int, card: CardUpdate, session: Session = Depends(get_session)):
    db_card = session.get(Card, card_id)
    if not db_card:
        raise HTTPException(status_code=404, detail="Card not found")
    if card.mastery_level is not None:
        db_card.mastery_level = card.mastery_level
    
    session.add(db_card)
    session.commit()
    session.refresh(db_card)
    return db_card

@app.get("/")
def read_root():
    return {"Hello": "World"}
